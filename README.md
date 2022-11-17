The kids are alright
================

A study of cohort differences in subjective wellbeing among young people
in Australia

## Age-, Period-, and Cohort-Effects

Since Fienberg & Mason (1978) argued that cohort effects are an
important consideration when estimating trends of a variable which
changes with age over the lifespan, social scientists, demographers and
epidemiologists have recognized that a critical concern is whether the
changes observed with age are also (partly) due to period or cohort
effects (e.g., Fukuda, 2013; Burns, Butterworth, & Crisp, 2020). Period
effects refer to variance over time that is common across all age
groups, such as due to a world war or a global pandemic that took place
in a certain period of history. Cohort effects, by contrast, refer to
variance over time that is specific to individuals born in or around
certain years (i.e., generational differences between millenials and
boomers).

Because age effects are a linear combination of period and cohort
effects (A = P - C), there is no technical way to solve the problem and
identify the unique effect of each in a linear model (Fienberg & Mason,
1978; Holford, 1983; Luo, 2013). Adding covariates to the linear APC
model changes the model but not the identification problem. The only way
to make it go away is by fiat; that is by conceding some constraint
whose appropriateness cannot be tested (Fienberg, 2013; Fienberg &
Mason, 1985; Mason & Fienberg, 1985).

The APC problem is a linear effects problem, and nonlinear effects and
possibly some interactions are estimable, depending on the nature of the
data.

<br><br>

## Results

This is the main plot showing birth cohort differences in affective
wellbeing (MHi-5 scores). Affective wellbeing (0-100) is getting worse
for younger generations, particularly *Millenials* (1990s), however
uncertainty is not quantified (e.g., confidence intervals) due to the
dependence that exists within birth cohorts due to repeated observations
of the same individuals.

##### Figure 1

![](figures/figure_1-1.png)<!-- -->

<br>

#### Cohort comparisons

We need to compare the smooth trends of each cohort to the next
generation (e.g., 1990s vs 1980s) so as to infer whether the trend is
increasing or decreasing *relative* to the next. We cannot compare
trends from birth cohorts more than two decades apart since there are no
overlapping age groups observed, so we will restrict ourselves to the
five pairwise comparisons between each cohort and the next.

We will use the generalized additive modelling (GAM) method provided by
Wood et al (Wood, 2004, 2006, 2011; Wood, Pya, & Säfken, 2016).

The smooth trends are expressed as spline functions and estimated by
quadratically penalized likelihood maximization for automatic smoothness
selection.

\[
y_{it} = \alpha(cohort_{[k]}) + f_{[k]} (age_{it}) + \epsilon_{it}
\]

\[
\epsilon \sim N(0, \Delta \sigma^2)
\]

Where \(\alpha_{[k]}\) is the mean subjective wellbeing score for each
\(k = 1...K\) cohort, and \(f_{[k]}\) are smooth functions for the trend
in MHi-5 scores over age for each cohort. To account for the
person-level dependency when survey participants are measured more than
once, we included a first-order autoregressive model AR(1) for the
residuals based on the unique crosswave ID for each person
\(i = 1...I\).

The smooth estimates, along with 95% credible/confidence intervals
(which include the uncertainty about the overall mean as well as the
centred smooth itself), are shown below. In each row the older cohort is
shown on the left as the reference smooth, and the estimated difference
between the reference and the younger cohort is shown on the right as
the difference smooth.

![](figures/figure_2-1.png)<!-- -->

<br>

The difference smooths reveal where the younger cohort is substantially
different from the older reference cohort where the confidence bounds
exclude zero (dotted line) (Marra & Wood, 2012; Wood, 2013). Inspection
of the *1990s difference* panel reveals the youngest cohort’s wellbeing
trajectory is significantly declining with age relative to the 1980s
cohort. After the age of 25, a person born in the 1990s is expected to
have lower subjective wellbeing than an equivalently aged person born
earlier (e.g., 1980s). The other cohorts also have declining
trajectories relative to their reference (older) cohort, albeit not as
substantial a decline and not as reliably beyond zero as the 1990s
cohort. The exception is the 1950s cohort which has a
(non-significantly) increasing trajectory relative to the reference
cohort, consistent with the prevailing view in popular and social media
that the “Baby Boomers” have had a great time at the expense of the
other generations.

<br><br>

## References

<div id="refs" class="references">

<div id="ref-burns2020age">

Burns, R. A., Butterworth, P., & Crisp, D. A. (2020). Age, sex and
period estimates of Australia’s mental health over the last 17 years.
*Australian & New Zealand Journal of Psychiatry*, *54*(6), 602–608.
<https://doi.org/10.1177/0004867419888289>

</div>

<div id="ref-fienberg2013cohort">

Fienberg, S. E. (2013). Cohort analysis’ unholy quest: A discussion.
*Demography*, *50*(6), 1981–1984.
<https://doi.org/10.1007/s13524-013-0251-z>

</div>

<div id="ref-fienberg1978identification">

Fienberg, S. E., & Mason, W. M. (1978). Identification and estimation of
age-period-cohort models in the analysis of discrete archival data.
*Sociological Methodology*, *10*, 1–67. <https://doi.org/10.2307/270764>

</div>

<div id="ref-fienberg1985specification">

Fienberg, S. E., & Mason, W. M. (1985). Specification and implementation
of age, period and cohort models. In *Cohort analysis in social
research* (pp. 45–88). Springer.
<https://doi.org/10.1007/978-1-4613-8536-3_3>

</div>

<div id="ref-fukuda2013happiness">

Fukuda, K. (2013). A happiness study using age-period-cohort framework.
*Journal of Happiness Studies*, *14*(1), 135–153.
<https://doi.org/10.1007/s10902-011-9320-4>

</div>

<div id="ref-holford1983estimation">

Holford, T. R. (1983). The estimation of age, period and cohort effects
for vital rates. *Biometrics*, 311–324.
<https://doi.org/10.2307/2531004>

</div>

<div id="ref-luo2013assessing">

Luo, L. (2013). Assessing validity and application scope of the
intrinsic estimator approach to the age-period-cohort problem.
*Demography*, *50*(6), 1945–1967.
<https://doi.org/10.1007/s13524-013-0243-z>

</div>

<div id="ref-marra2012coverage">

Marra, G., & Wood, S. N. (2012). Coverage properties of confidence
intervals for generalized additive model components. *Scandinavian
Journal of Statistics*, *39*(1), 53–74.
<https://doi.org/10.1111/j.1467-9469.2011.00760.x>

</div>

<div id="ref-mason1985cohort">

Mason, W. M., & Fienberg, S. (1985). *Cohort analysis in social
research: Beyond the identification problem*. Springer Science &
Business Media. <https://doi.org/10.1007/978-1-4613-8536-3_1>

</div>

<div id="ref-wood2004stable">

Wood, S. N. (2004). Stable and efficient multiple smoothing parameter
estimation for generalized additive models. *Journal of the American
Statistical Association*, *99*(467), 673–686.
<https://doi.org/10.1198/016214504000000980>

</div>

<div id="ref-wood2006low">

Wood, S. N. (2006). Low-rank scale-invariant tensor product smooths for
generalized additive mixed models. *Biometrics*, *62*(4), 1025–1036.
<https://doi.org/10.1111/j.1541-0420.2006.00574.x>

</div>

<div id="ref-wood2011fast">

Wood, S. N. (2011). Fast stable restricted maximum likelihood and
marginal likelihood estimation of semiparametric generalized linear
models. *Journal of the Royal Statistical Society: Series B (Statistical
Methodology)*, *73*(1), 3–36.
<https://doi.org/10.1111/j.1467-9868.2010.00749.x>

</div>

<div id="ref-wood2013p">

Wood, S. N. (2013). On p-values for smooth components of an extended
generalized additive model. *Biometrika*, *100*(1), 221–228.
<https://doi.org/10.1093/biomet/ass048>

</div>

<div id="ref-wood2016smoothing">

Wood, S. N., Pya, N., & Säfken, B. (2016). Smoothing parameter and model
selection for general smooth models. *Journal of the American
Statistical Association*, *111*(516), 1548–1563.
<https://doi.org/10.1080/01621459.2016.1180986>

</div>

</div>
