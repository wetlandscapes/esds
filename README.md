# Earth System Data Science (ESDS)

A repository of examples of using different statistical and machine learning algorithms (mostly in R) in hydropedology

## Why data science?

### What is data science?

### Tools for data science

I'll largely be focused on using R.

## About the data

### Hydrology data

A combination of USGS stream discharge, landscape, and climate data.

#### Stream data -- National Water Information System

https://help.waterdata.usgs.gov/
https://owi.usgs.gov/R/dataRetrieval.html

#### Landscape data -- GAGES-II

https://www.sciencebase.gov/catalog/item/59692a64e4b0d1f9f05fbd39

#### Climate data -- PRISM

http://www.prism.oregonstate.edu/

Keep it simple, so focus on:

* Precipitation
* Mean temperature
* Dew point temperature? Use this to get at relative humidity?

#### Climate data -- NRCS SNOTEL

* How can I automate the download of these data?
* Could I use these data to optimize a phase curve via logistic regression?


### Soils data

Focus: ISRIC soils information (https://www.isric.org/)
Data availability: ISRIC Soil Data Hub (https://data.isric.org)

### Data manipulation

## Questions of interest

* Is there a relationship between soil attributes and climate (Koppen-Geiger)?
    * We know this from the five soil-forming factors, but can we quantify the relationship?
* Can I tell which continent a soil came from?
* What are the most important attributes defining a soil (relative to the data I have)? (PCA or NMDS question.)
* Do different soil attributes influence one another? (SEM question)
* Are mean annual temperature data from PRISM and actual station data different from each other?
    * Is there geographic bias in the errors or significant differences?
    * Pair-wise __t-tests__ or other comparisons (Mann-Whitney)
    * Download the data from CompBio
        * Frequentist vs Bayesian methods
* Can we predict the phase of snow using air temperature and other environmental data?
    * This is a classification problem that could be addressed with __logistic regression__ and __SVM__.
* Are there significant trends in annual discharge over time?
    * __Linear regression__
    * Map out the slope of significant trends across the US.
        * Use leaflet and clickable links to see individual annual hydrographs marked with a colored trend line and highlighting abnormal years using the emperical density function.
    * Include both Frequentist and Bayesian forms of the analysis.
* Is there a relationship between annual discharge, temperature, snow, elevation, etc?
    * __Multiple linear regression__
* What role do different landscape features have on the above relationships?
    * Could use the GAGES-II data set for this
    * __Hierarchical multiple linear regression__
    * Frequentist and Bayesian
* Are their "natural" groups of discharge sensitivity (represented by the steepness of the slope)?
    * __Discriminant analysis__

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
            * Is this the same thing as discriminant analysis (which uses Bayes' Theorem)
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
