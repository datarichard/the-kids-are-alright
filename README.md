The kids are alright
================

A study of cohort differences in subjective wellbeing among young people
in Australia

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
Wood et al (see references).

The smooth trends are expressed as spline functions and estimated by
quadratically penalized likelihood maximization for automatic smoothness
selection.

![
y\_{it} = \\alpha(cohort\_{\[k\]}) + f\_{\[k\]} (age\_{it}) + \\epsilon\_{it} \\\\
\\epsilon \\sim N(0, \\Delta \\sigma^2)
](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%0Ay_%7Bit%7D%20%3D%20%5Calpha%28cohort_%7B%5Bk%5D%7D%29%20%2B%20f_%7B%5Bk%5D%7D%20%28age_%7Bit%7D%29%20%2B%20%5Cepsilon_%7Bit%7D%20%5C%5C%0A%5Cepsilon%20%5Csim%20N%280%2C%20%5CDelta%20%5Csigma%5E2%29%0A "
y_{it} = \alpha(cohort_{[k]}) + f_{[k]} (age_{it}) + \epsilon_{it} \\
\epsilon \sim N(0, \Delta \sigma^2)
")

Where
![\\alpha\_{\[k\]}](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%5Calpha_%7B%5Bk%5D%7D "\alpha_{[k]}")
is the mean subjective wellbeing score for each
![k = 1...K](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;k%20%3D%201...K "k = 1...K")
cohort, and
![f\_{\[k\]}](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;f_%7B%5Bk%5D%7D "f_{[k]}")
are smooth functions for the trend in MHi-5 scores over age for each
cohort. To account for the person-level dependency when survey
participants are measured more than once, we included a first-order
autoregressive model AR(1) for the residuals based on the unique
crosswave ID for each person
![i = 1...I](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;i%20%3D%201...I "i = 1...I").

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
exclude zero (dotted line). Inspection of the *1990s difference* panel
reveals the youngest cohort’s wellbeing trajectory is significantly
declining with age relative to the 1980s cohort. After the age of 25, a
person born in the 1990s is expected to have lower subjective wellbeing
than an equivalently aged person born earlier (e.g., 1980s). The other
cohorts also have declining trajectories relative to their reference
(older) cohort, albeit not as substantial a decline and not as reliably
beyond zero as the 1990s cohort. The exception is the 1950s cohort which
has a (non-significantly) increasing trajectory relative to the
reference cohort, consistent with the prevailing view in popular and
social media that the “Baby Boomers” have had a great time at the
expense of the other generations.

<br><br>

## References

Wood, S.N., N. Pya and B. Saefken (2016), Smoothing parameter and model
selection for general smooth models (with discussion). Journal of the
American Statistical Association 111, 1548-1575 doi:
10.1080/01621459.2016.1180986

Wood, S.N. (2011) Fast stable restricted maximum likelihood and marginal
likelihood estimation of semiparametric generalized linear models.
Journal of the Royal Statistical Society (B) 73(1):3-36

Wood, S.N. (2004) Stable and efficient multiple smoothing parameter
estimation for generalized additive models. J. Amer. Statist. Ass.
99:673-686

Marra, G and S.N. Wood (2012) Coverage Properties of Confidence
Intervals for Generalized Additive Model Components. Scandinavian
Journal of Statistics, 39(1), 53-74

Wood, S.N. (2013a) A simple test for random effects in regression
models. Biometrika 100:1005-1010

Wood, S.N. (2013b) On p-values for smooth components of an extended
generalized additive model. Biometrika 100:221-228
