## Survival Analysis
library(INLA); library(brinla)

# Example 1: Semipararmetric Piecewise Constant Hazard Models
# Read the data
data(ACTG320, package = "brinla")
str(ACTG320)
inla.setOption("enable.inla.argument.weights", TRUE)

# Fit the Cox ph model using conventional method
library(survival)
ACTG320.coxph <- coxph(Surv(time, censor) ~ tx + age + sex + priorzdv, data = ACTG320)
# summary(ACTG320.coxph)
round(coef(summary(ACTG320.coxph)), 4)

# Fit a semipararmetric Piecewise Constant Hazard Model using INLA
ACTG320.formula = inla.surv(time, censor) ~ tx + age + sex + priorzdv
ACTG320.inla1 <- inla(ACTG320.formula,  family = "coxph", data = ACTG320, control.hazard = list(model = "rw1", n.intervals = 20), control.compute = list(dic = TRUE))
# summary(ACTG320.inla1)
round(ACTG320.inla1$summary.fixed, 4)
# Plot the baseline hazard function
bri.basehaz.plot(ACTG320.inla1)

# -----------------------------------------
# Fit a stratified proportional Hazard Model
ACTG320$cd4group <- as.numeric(cut(ACTG320$cd4, breaks = c(-Inf, quantile(ACTG320$cd4, probs = c(.25,.5,.75)), Inf), labels = c("1","2","3","4")))
ACTG320.inla2 <- inla(ACTG320.formula,  family = "coxph", data = ACTG320, control.hazard = list(model = "rw1", n.intervals = 20, strata.name = "cd4group"), control.compute = list(dic = TRUE))
# summary(ACTG320.inla2)
round(ACTG320.inla2$summary.fixed, 4)
# Plot the stratified baseline hazard functions
bri.basehaz.plot(ACTG320.inla2)

# Compare DICs
c(ACTG320.inla1$dic$dic, ACTG320.inla2$dic$dic)

# -----------------------------------------
# Fit a parametric survival Model (AFT models)
# load the larynx dataset
data(larynx, package = "brinla")
# use the frequentist approach
larynx.wreg <- survreg(Surv(time, delta)~ as.factor(stage) + age, data=larynx, dist="weibull")
# summary(larynx.wreg)
round(summary(larynx.wreg)$table, 4)

## INLA weibull model
formula = inla.surv(time, delta) ~ as.factor(stage) + age
larynx.inla1 <- inla(formula, control.compute = list(dic = TRUE), family = "weibullsurv", data = larynx)
# summary(larynx.inla1)
round(larynx.inla1$summary.fixed, 4)

## INLA Exponential model
larynx.inla2 <- inla(formula, control.compute = list(dic = TRUE), family = "exponentialsurv", data = larynx)
# summary(larynx.inla2)
round(larynx.inla2$summary.fixed, 4)

## INLA Cox model
larynx.inla3 <- inla(formula, control.compute = list(dic = TRUE), family = "coxph", data = larynx, control.hazard=list(model="rw1", n.intervals=20))
# summary(larynx.inla3)
round(larynx.inla3$summary.fixed, 4)

# -----------------------------------------
# Model Diagnosis
# compute Baysian residuals from survival models
larynx.inla1.res <- bri.surv.resid(larynx.inla1, larynx$time, larynx$delta)
larynx.inla2.res <- bri.surv.resid(larynx.inla2, larynx$time, larynx$delta)
larynx.inla3.res <- bri.surv.resid(larynx.inla3, larynx$time, larynx$delta)

## Cox-Snell Residual plots
par(mfrow=c(1,3))
bri.csresid.plot(larynx.inla1.res, main = "Weibull model")
bri.csresid.plot(larynx.inla2.res, main = "Exponential model")
bri.csresid.plot(larynx.inla3.res, main = "Cox model")

## deviance residual plots
par(mfrow=c(1,3))
bri.dresid.plot(larynx.inla1.res, larynx$age, xlab = "age", main = "Weibull model")
bri.dresid.plot(larynx.inla2.res, larynx$age, xlab = "age", main = "Exponential model")
bri.dresid.plot(larynx.inla3.res, larynx$age, xlab = "age", main = "Cox model")

## martingale residual plots
par(mfrow=c(1,3))
bri.mresid.plot(larynx.inla1.res, larynx$diagyr, smooth = TRUE, xlab = "diagyr", main = "Weibull model")
bri.mresid.plot(larynx.inla2.res, larynx$diagyr, smooth = TRUE, xlab = "diagyr", main = "Exponential model")
bri.mresid.plot(larynx.inla3.res, larynx$diagyr, smooth = TRUE, xlab = "diagyr", main = "Cox model")

# -----------------------------------------
## interval censoring data
# load the tooth24 dataset
data(tooth24, package = "brinla")
str(tooth24)

# Fit the loglogistic survival model using the frequentist approach
tooth24$cens <- with(tooth24, ifelse(RIGHT == 999, 0, 3))
sur24 <- with(tooth24, Surv(LEFT, RIGHT, cens, type = "interval"))
tooth24.survreg <- survreg(sur24 ~ SEX + DMF, data = tooth24, dist="loglogistic")
# summary(tooth24.survreg)
round(summary(tooth24.survreg)$table, 4)
round(summary(tooth24.survreg)$scale, 4)
## Weibull model seems problematic. we can not get alpha estimate.

## Fit the loglogistic survival model using INLA
tooth24.formula = inla.surv(LEFT, cens, RIGHT) ~ SEX + DMF 
tooth24.inla <- inla(tooth24.formula,  family = "loglogistic", data = tooth24)
# summary(tooth24.inla)
round(tooth24.inla$summary.fixed, 4)
round(tooth24.inla$summary.hyper, 4) 

## Compute the proportional odds of girls under the AFT model
exp(-1*tooth24.inla$summary.fixed[2,1]/(1/tooth24.inla$summary.hyper[1,1]))


## ----------------
## Weibull Frailty Models
# load the kidney data
data(kidney, package = "survival")

# Fit the frailty model using the frequentist approach
kidney.weib <- survreg(Surv(time,status) ~ age + sex + disease + frailty.gaussian(id), dist='weibull', data = kidney)
round(summary(kidney.weib)$table, 4)
round(kidney.weib$history$`frailty.gaussian(id)`$theta, 4)

# Fit the frailty Model using INLA
formula = inla.surv(time, status) ~ age + sex + disease + f(id, model = "iid", hyper = list(prec = list(param=c(0.1, 0.1)))) 
kidney.inla <- inla(formula, family = "weibullsurv", data = kidney) 
#summary(kidney.inla)
round(kidney.inla$summary.fixed, 4)
round(kidney.inla$summary.hyper, 4)

# Improve the estimates of the posterior marginals for the hyperparameters
kidney.inla.hp <- inla.hyperpar(kidney.inla)
# summary(kidney.inla.hp)
round(kidney.inla.hp$summary.hyper, 4)

# compute the estimate of frailty sd parameter for id
round(bri.hyperpar.summary(kidney.inla.hp),4)
library(ggplot2)
bri.hyperpar.plot(kidney.inla.hp, together = F)

## Joint modeling
# load the data
data(joint, package = "brinla")
# str(joint)
longdat <- joint$longitudinal
survdat <- joint$survival
n1 <- nrow(longdat)
n2 <- nrow(survdat)

# prepare the response variable
y.long <- c(longdat$y, rep(NA, n2))
y.surv <- inla.surv(time = c(rep(NA, n1), survdat$SURVTIME), event = c(rep(NA, n1), survdat$CENSOR))
Yjoint <- list(y.long, y.surv)

# prepare the fixed covariate
linear.covariate <- data.frame(mu = as.factor(c(rep(1, n1), rep(2, n2))), l.TIME = c(longdat$TIME, rep(0, n2)), l.TIMEDRUG = c(longdat$TIMEDRUG, rep(0, n2)), l.SEX = c(longdat$SEX, rep(0, n2)), l.PREVOI = c(longdat$PREVOI, rep(0, n2)), l.STRATUM = c(longdat$STRATUM, rep(0, n2)), s.DRUG = c(rep(0, n1), survdat$DRUG), s.SEX = c(rep(0, n1), survdat$SEX), s.PREVOI = c(rep(0, n1), survdat$PREVOI), s.STRATUM = c(rep(0, n1), survdat$STRATUM))
ntime <- length(unique(longdat$TIME))

# prepare the random covariate
random.covariate <- list(U11 = c(rep(1:n2, each = ntime),rep(NA, n2)), U21 = c(rep(n2+(1:n2), each = ntime),rep(NA, n2)), U12 = c(rep(NA, n1), 1:n2), U22 = c(rep(NA, n1), n2+(1:n2)), U3 = c(rep(NA, n1), 1:n2))

# finalize the joint dataset for R-INLA program
joint.data <- c(linear.covariate,random.covariate)
joint.data$Y <- Yjoint

##MODEL
formula = Y ~ mu + l.TIME + l.TIMEDRUG + l.SEX + l.PREVOI + l.STRATUM + s.DRUG + s.SEX + s.PREVOI + s.STRATUM - 1 + f(U11 , model="iid2d", param = c(23,100,100,0), initial = c(-2.7,0.9,-0.22), n=2*n2) + f(U21, l.TIME, copy="U11") + f(U12, copy="U11", fixed = FALSE, param=c(0,0.01), initial = -0.2) + f(U22, copy="U11", fixed = FALSE, param = c(0,0.01), initial = -1.6)

joint.inla <- inla(formula, family = c("gaussian","exponentialsurv"), data = joint.data, control.compute=list(dic=TRUE))
# summary(joint.inla)
round(joint.inla$summary.fixed, 4)
round(joint.inla$summary.hyper, 4)

sessionInfo()
