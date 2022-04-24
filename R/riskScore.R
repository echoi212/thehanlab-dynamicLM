#' Calcutes dynamic risk score at a time for an individual (helper to predLMrisk)
#'
#' @param fm Fitted super model, of class "LMCSC" or "LMcox"
#' @param tLM Landmarking time point at which to calculate risk score (time at which the prediction is made)
#' @param data Dataframe (single row) of individual. Must contain the original covariates.
#' @param func_covars A list of functions to use for interactions between LMs and covariates.
#' @param func_LMs A list of functions to use for transformations of the landmark times.
#'
#' @return Numeric risk score
#' @export
#'
riskScore <- function(fm, tLM, data, func_covars, func_LMs)
{
  coefs <- fm$coefficients
  pred_covars <- names(coefs)
  idx_LM_covars <- grep("LM",pred_covars, fixed=TRUE)
  LM_covars <- pred_covars[idx_LM_covars]
  bet_covars <- pred_covars[-idx_LM_covars]

  # coef_LM1*g1(t) + coef_LM2*g2(t) + ...
  risk <- sum(
    sapply(LM_covars, function(coef_name){
      # Get associated function
      n <- nchar(coef_name)
      idx <- as.numeric(substr(coef_name,n,n))
      g <- func_LMs[[idx]]
      # Multiply by coef
      return(g(tLM) * coefs[coef_name])
    })
    # X1*coef + X1*t*coef + X1*t^2*coef + ..
  ) + sum(
    sapply(bet_covars, function(coef_name){
      # Get associated function
      n <- nchar(coef_name)
      idx <- as.numeric(substr(coef_name,n,n))
      f <- func_covars[[idx]]
      # Get associated covariate info (remove _i from the name)
      covar <- substr(coef_name,1,n-2)
      # Multiply both by coef
      return(f(tLM) * coefs[coef_name] * data[,covar])
    })
  )
  return(risk)
}