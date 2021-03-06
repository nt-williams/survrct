#' Create RCT Survival Metadata
#'
#' Compute metadata to be used for estimation of model-robust covariate adjusted
#' restricted mean survival time and survival probability in a two-arm randomized
#' controlled trial using targeted maximum likelihood estimation.
#'
#' @param outcome.formula An object of class "formula". The left hand side should be
#'   specified using \code{Surv(time, status)} where time is the name of the
#'   variable containing follow-up time and status is the name of the indicator variable
#'   with 0 = right censored and 1 = event at \code{time}. The right hand
#'   side should contain the target variable of interest and baseline prognostic covariates.
#' @param trt.formula An object of class "formula". The left hand side should be the name
#'   of the binary (coded as 0 and 1) treatment variable. The right hand side should specify the
#'   names of variables used to estimate the propensity.
#' @param data A data frame containing the variables in the model.
#' @param coarsen An optional integer that specifies if and how \code{time} should
#'   be categorized into coarser intervals.
#' @param algo Method to be used for fitting the hazard and censoring nuisance parameters.
#'   Automatically set to \code{"glm"} if less than two covariates for adjustment are
#'   specified in \code{outcome.formula}. The propensity is always estimated using a GLM.
#' @param crossfit Should the estimator be crossfit? Ignored if \code{algo} is \code{"glm"} or \code{"lasso"}.
#'
#' @family survrct functions
#'
#' @return An R6 object of class "Survival".
#' @export
#'
#' @examples
#' survrct(Surv(days, event) ~ A + age + sex + dyspnea + bmi,
#'         A ~ 1, data = c19.tte)
survrct <- function(outcome.formula, trt.formula,
                    data, coarsen = 1,
                    algo = c("glm", "lasso", "rf", "xgboost"),
                    crossfit = TRUE) {
  out <- Survival$
    new(outcome.formula, trt.formula, data)$
    prepare_data(coarsen)$
    fit_nuis(match.arg(algo), crossfit)
  return(out)
}

#' Estimate Restricted Mean Survival Time
#'
#' @param metadata An object of class "Survival" generated by a call to \code{survrct()}.
#' @param horizon The time horizon to evaluate at. If \code{NULL}, computes
#'   RMST at all possible time horizons.
#'
#' @family survrct functions
#' @seealso \code{\link{survrct}} for creating \code{metadata}.
#'
#' @return A list of class \code{rmst} containing the
#'   computed estimates for each time horizon including
#'   the efficient influence function, standard errors, and
#'   confidence intervals.
#'
#' @export
#'
#' @examples
#' surv <- survrct(Surv(days, event) ~ A + age + sex + dyspnea + bmi,
#'                 A ~ 1, data = c19.tte)
#' rmst(surv, 14)
rmst <- function(metadata, horizon = NULL) {
  metadata$evaluate_horizon(horizon, "rmst")
  out <- list(estimator = metadata$estimator,
              horizon = metadata$horizon,
              estimates = compute_rmst(metadata))
  class(out) <- "rmst"
  out
}

#' Estimate Survival Probabilities
#'
#' @param metadata An object of class "Survival" generated by a call to \code{survrct()}.
#' @param horizon The time horizon to evaluate at. If \code{NULL}, computes
#'   survival probabilities at all time points.
#'
#' @family survrct functions
#' @seealso \code{\link{survrct}} for creating \code{metadata}.
#'
#' @return A list of class \code{survprob} containing the computed estimates
#'   for each time horizon including the efficient influence function, standard errors,
#'   and confidence intervals.
#'
#' @export
#'
#' @examples
#' surv <- survrct(Surv(days, event) ~ A + age + sex + dyspnea + bmi,
#'                 A ~ 1, data = c19.tte)
#' survprob(surv, 14)
survprob <- function(metadata, horizon = NULL) {
  metadata$evaluate_horizon(horizon, "survprob")
  out <- list(estimator = metadata$estimator,
              horizon = metadata$horizon,
              estimates = compute_survprob(metadata))
  class(out) <- "survprob"
  out
}

#' Create RCT Ordinal Metadata
#'
#' Compute metadata to be used for estimation of model-robust covariate adjusted
#' average log odds ratio, Mann-Whitney statistic, and counterfactual marginal CDF
#' and PMF in a two-arm randomized controlled trial using
#' targeted maximum likelihood estimation.
#'
#' @param outcome.formula An object of class "formula". The left hand side should be
#'   the outcome variable. The right hand
#'   side should contain the target variable of interest and baseline prognostic covariates.
#' @param trt.formula An object of class "formula". The left hand side should be the name
#'   of the binary (coded as 0 and 1) treatment variable. The right hand side should specify the
#'   names of variables used to estimate the propensity.
#' @param data A data frame containing the variables in the model.
#' @param algo Method to be used for fitting nuisance parameters. Automatically set to "glm" if
#'   less than two covariates for adjustment are specified in \code{formula}.
#' @param crossfit Should the estimator be crossfit? Ignored if \code{algo} is \code{"glm"} or \code{"lasso"}
#'
#' @family ordinal functions
#'
#' @return An R6 object of class "Ordinal".
#' @export
#'
#' @examples
#' ordinalrct(state_ordinal ~ A + age, A ~ 1, data = c19.ordinal)
ordinalrct <- function(outcome.formula,
                       trt.formula, data,
                       algo = c("glm", "lasso", "rf", "xgboost"),
                       crossfit = TRUE) {
  out <- Ordinal$
    new(outcome.formula, trt.formula, data)$
    prepare_data()$
    fit_nuis(match.arg(algo), crossfit)
  return(out)
}

#' Estimate Average Log Odds Ratio
#'
#' @param metadata An object of class "Ordinal" generated by a call to \code{ordinalrct()}.
#'
#' @family ordinalrct functions
#' @seealso \code{\link{ordinalrct}} for creating \code{metadata}.
#'
#' @return A list of class \code{lor} containing the computed estimates including the
#'   efficient influence function, standard errors, and confidence intervals.
#'
#' @export
#' @examples
#' rct <- ordinalrct(state_ordinal ~ A + age, A ~ 1, data = c19.ordinal)
#' log_or(rct)
log_or <- function(metadata) {
  out <- list(estimator = metadata$estimator,
              estimates = compute_lor(metadata))
  class(out) <- "lor"
  out
}

#' Estimate the Cumulative Distribution Function
#'
#' @param metadata An object of class "Ordinal" generated by a call to \code{ordinalrct()}.
#'
#' @family ordinalrct functions
#' @seealso \code{\link{ordinalrct}} for creating \code{metadata}.
#'
#' @return A list of class \code{cdf} containing the computed estimates
#'   including the efficient influence function, standard errors,
#'   and confidence intervals.
#'
#' @export
#' @examples
#' rct <- ordinalrct(state_ordinal ~ A + age, A ~ 1, data = c19.ordinal)
#' cdf(rct)
cdf <- function(metadata) {
  out <- list(levels = levels(metadata$data[[metadata$Y]]),
              estimator = metadata$estimator,
              estimates = compute_cdf(metadata))
  class(out) <- "cdf"
  out
}

#' Estimate the Probability Mass Function
#'
#' @param metadata An object of class "Ordinal" generated by a call to \code{ordinalrct()}.
#'
#' @family ordinalrct functions
#' @seealso \code{\link{ordinalrct}} for creating \code{metadata}.
#'
#' @return A list of class \code{pmf} containing the computed estimates
#'   including the efficient influence function, standard errors,
#'   and confidence intervals.
#'
#' @export
#' @examples
#' rct <- ordinalrct(state_ordinal ~ A + age, A ~ 1, data = c19.ordinal)
#' pmf(rct)
pmf <- function(metadata) {
  out <- list(levels = levels(metadata$data[[metadata$Y]]),
              estimator = metadata$estimator,
              estimates = compute_pmf(metadata))
  class(out) <- "pmf"
  out
}

#' Estimate the Mann-Whitney Statistic
#'
#' Computes the Mann-Whitney estimand; the probability that a randomly drawn patient
#' from the treated arm has a better outcome than a randomly drawn patient from
#' the control arm, with ties broken at random
#'
#' @param metadata An object of class "Ordinal" generated by a call to \code{ordinalrct()}.
#'
#' @family ordinalrct functions
#' @seealso \code{\link{ordinalrct}} for creating \code{metadata}.
#'
#' @return A list of class \code{mannwhit} containing the computed estimates
#'   including the efficient influence function, standard errors,
#'   and confidence intervals.
#'
#' @export
#' @examples
#' rct <- ordinalrct(state_ordinal ~ A + age, A ~ 1, data = c19.ordinal)
#' mannwhitney(rct)
mannwhitney <- function(metadata) {
  out <- list(estimator = metadata$estimator,
              estimates = compute_mw(metadata))
  class(out) <- "mannwhit"
  out
}
