# =========================================================================
# PROJECT: Enterprise-Grade Data Sanitization & Export Pipeline
# ARCHITECTURE: Explicit Contracts, Vectorized Performance, & Multi-Format Load
# AUTHOR: LUIZ AUGUSTO BENTEMULER RODRIGUES / GITHUB: Augusto-Bentemuler
# =========================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(stringi)
  library(readr)
  library(writexl) # Native Excel export avoiding external Java dependencies
})

sanitize_and_export_data <- function(df, output_dir = "output_data", target_text_cols = NULL) {
  message("[INFO] [SANITY] Initializing corporate data sanitization pipeline...")
  
  # 1. Defensive Input Contract Validation
  if (!is.data.frame(df) || nrow(df) == 0) {
    stop("[CRITICAL] Input Contract Failure: The provided object is not a valid data.frame or is empty.")
  }
  
  initial_rows <- nrow(df)
  
  # 2. Structural Hygiene (Column naming standardization and safe UTF-8 normalization)
  cleaned_df <- df %>%
    rename_with(~ .x %>%
                  iconv(from = "", to = "UTF-8", sub = "byte") %>%
                  str_to_lower() %>% 
                  str_trim() %>% 
                  str_replace_all("[^a-z0-9_]", "_") %>%
                  str_replace_all("_{2,}", "_"))
  
  cols_to_clean <- if (!is.null(target_text_cols)) {
    intersect(target_text_cols, names(cleaned_df))
  } else {
    names(cleaned_df)[sapply(cleaned_df, is.character)]
  }
  
  if (length(cols_to_clean) > 0) {
    
    # 3. Vectorized String Cleaning and Masked Null Resolution
    cleaned_df <- cleaned_df %>%
      mutate(across(all_of(cols_to_clean), ~ {
        val <- iconv(.x, from = "", to = "UTF-8", sub = "byte")
        val <- str_trim(val)
        val <- str_squish(val)
        
        # Corporate dictionary of human-generated masked nulls
        false_nulls <- c("", "na", "n/a", "null", "NULL", "NaN", "nan", "none", 
                        "NONE", "-", "--", "?", "nil", "nulo", "NULO", "undefined")
        
        ifelse(val %in% false_nulls | is.na(val), NA_character_, val)
      })) %>%
      
      # 4. Vectorized Text Normalization (C++ Backend Performance)
      mutate(across(all_of(cols_to_clean), ~ {
        non_na_idx <- !is.na(.x)
        res <- .x
        if (any(non_na_idx)) {
          res[non_na_idx] <- stringi::stri_trans_general(res[non_na_idx], "Latin-ASCII")
          res[non_na_idx] <- str_to_lower(res[non_na_idx])
        }
        res
      }))
  }
  
  # 5. Deterministic Deduplication
  cleaned_df <- cleaned_df %>% distinct()
  
  final_rows <- nrow(cleaned_df)
  duplicates_removed <- initial_rows - final_rows
  
  # -------------------------------------------------------------------------
  # 6. LOAD / LOCAL PERSISTENCE LAYER
  # -------------------------------------------------------------------------
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message(sprintf("[INFO] [LOAD] Directory successfully created: '%s'", output_dir))
  }
  
  execution_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  csv_path  <- file.path(output_dir, paste0("clean_data_", execution_timestamp, ".csv"))
  xlsx_path <- file.path(output_dir, paste0("clean_data_", execution_timestamp, ".xlsx"))
  
  # Export CSV with strict UTF-8 encoding (ensures rendering integrity across Excel/BI tools)
  readr::write_csv(cleaned_df, csv_path, na = "")
  
  # Export native XLSX
  writexl::write_xlsx(cleaned_df, path = xlsx_path)
  
  # 7. Observability and Structured Audit Logging
  message("[AUDIT] ----------------------------------------------------")
  message(sprintf("[AUDIT] Status: Pipeline successfully executed and files exported."))
  message(sprintf("[AUDIT] Initial Row Count:    %d", initial_rows))
  message(sprintf("[AUDIT] Final Row Count:      %d", final_rows))
  message(sprintf("[AUDIT] Duplicates Removed:   %d", duplicates_removed))
  message(sprintf("[AUDIT] CSV Output Path:      %s", csv_path))
  message(sprintf("[AUDIT] XLSX Output Path:     %s", xlsx_path))
  message(sprintf("[AUDIT] Sanitized Columns:    %s", 
                  if (length(cols_to_clean) > 0) paste(cols_to_clean, collapse = ", ") else "None"))
  message("[AUDIT] ----------------------------------------------------")
  
  return(cleaned_df)
}

# -------------------------------------------------------------------------
# EXECUTION EXAMPLE:
# -------------------------------------------------------------------------
# sample_messy_data <- data.frame(
#   "Client Name" = c("  John Smith  ", "MARIA", "john smith", "N/A"),
#   "City" = c("São Paulo", "rio de janeiro", "SÃO PAULO", "-")
# )
# 
# processed_data <- sanitize_and_export_data(sample_messy_data)
