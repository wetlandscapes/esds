# Data science in hydropedology

A repository of examples of using different statistical and machine learning algorithms (mostly in R) in hydropedology

## Why data science?

### What is data science?

### Tools for data science

I'll largely be focused on using R.

## About the data

For the sake of consistency, I'll be focusing on a single data set, which I will then "interogate" using different data science tools.

Focus: ISRIC soils information (https://www.isric.org/)
Data availability: ISRIC Soil Data Hub (https://data.isric.org)

### Data manipulation

## Questions of interest

* Is there a relationship between soil attributes and climate (Koppen-Geiger)?
    * We know this from the five soil-forming factors, but can we quantify the relationship?
* Can I tell which continent a soil came from?
* What are the most important attributes defining a soil (relative to the data I have)? (PCA or NMDS question.)
* Do different soil attributes influence one another? (SEM question)

## Algorithms to investigate

How should I organize these algorithms? By Data type output? (This will help me figure out how to organize the site.)

* Data types
   * Categorical
       * Nominal (Categories with no obvious relationship)
       * Ordinal (Categories in which order does matter)
   * Numerical
       * Interval (Integer data that maintain the same distance from each other -- -5, 0, 5, 10)
       * Ratio
       
* Further attributes to consider
    * Data output type
    * Data input type
    * Parameter type
        * Single
        * Multiple
            * Mixed (categorical and numerical)

### The algorithms

* Linear regression
   * Frequentist
   * Bayesian
* Support Vector Machine
    * https://shuzhanfan.github.io/2018/05/understanding-mathematics-behind-support-vector-machines/
    * Support Vector Regression
        * https://www.svm-tutorial.com/2014/10/support-vector-regression-r/
            * `e1071`
* Generalized Linear Model (GLM)
    * Logistic regression
        * Frequentist
        * Bayesian
    * Other GLMs
        * Frequentist
        * Bayesian
* Generalized Additive Model (GAM)
    * Frequentists
        * https://m-clark.github.io/generalized-additive-models/
    * Bayesian
        * https://www.fromthebottomoftheheap.net/2018/04/21/fitting-gams-with-brms/
* Dimensional reduction
    * PCA
    * NMDS
* Classification
    * Supervised
        * Random forest
            * `party`
        * Naive Bayes
    * Unsupervised
        * K-means clustering
        * kNN (K-nearest neighbors)
* Gradient boosting
* Collaborative filtering
* ARIMA
    * https://otexts.com/fpp2/
        * https://otexts.com/fpp2/arima.html
* Neural Nets
* A/B testing
    * t-tests
    * Mann-Whitney
* Hierarchical modeling
    * Focus: van Genuchten model
    * Frequentist
        * `lme4`
    * Bayesian
        * `Stan`
    * Deeply nested
* Structural equation modeling
    * Frequentists
    * Bayesian
    
## Uncertainty

Other topics that don't fit neatly into the space above.

* Leave-one-out cross validation
* k-folds cross validation

## More about machine learning in R

* https://mlr.mlr-org.com/index.html

## Statistical learning resources

* https://www.youtube.com/playlist?list=PLOg0ngHtcqbPTlZzRHA2ocQZqB1D_qZ5V
