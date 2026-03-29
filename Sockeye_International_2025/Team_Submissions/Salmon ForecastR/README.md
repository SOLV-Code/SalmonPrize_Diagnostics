# Team Salmon ForecastR



## Team Members

Team ForecastR includes:

* [Gottfried Pestal, SOLV Consulting](https://github.com/SOLV-Code)
* [Charmaine Carr-Harris, DFO](https://github.com/charmainecarrharris)
* [Michael Folkes, DFO](https://github.com/MichaelFolkes)
* [L. Antonio Vélez-Espino, DFO](https://github.com/avelez-espino)

We are developers and active users of the [**forecastR**](https://github.com/SalmonForecastR)  toolkit, which consists of an [R package](https://github.com/SalmonForecastR/ForecastR-Package) and a shiny app ([repo](https://github.com/SalmonForecastR/ForecastR-App), [SOLV server](https://solv-code.shinyapps.io/forecastr/), [PSC server](https://psc1.shinyapps.io/ForecastR/)). 


## The *forecastR* Package

**forecastR** is designed to streamline the exploration of fundamentally different model types within an iterative working group process. Initial development has focused on the suite of models routinely used for Chinook salmon forecasts by the [Chinook Technical Committee of the Pacific Salmon Commission](https://www.psc.org/about-us/structure/committees/technical/chinook/).

The R package includes functions to complete retrospective evaluations and rank a suite of alternative models. The shiny app allows users to explore retrospective model rankings and vary specifications in real time (e.g., add another model, revise the ranking criteria, and rerun). For details, check out the latest **[ForecastR Report](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwiMi47T1rrvAhVVJjQIHQ-nCNYQFjAGegQIChAD&url=https%3A%2F%2Fwww.psc.org%2Fdownload%2F585%2Fvery-high-priority-chinook%2F11704%2Fs18-vhp15a-forecastr-tools-to-automate-forecasting-procedures-for-salmonid-terminal-run-and-escapement.pdf&usg=AOvVaw2ZHMiJb0dBhjytGgM8lgvZ)**.


## Approach

We approached the 2025 competition as an illustration of the full workflow we've designed the **forecastR** tool kit for. Therefore, we restricted the analyses to model forms that are already included in the package and worked through 8 steps:


- Step 1: Explore stock data and reorganize into forecastR format
- Step 2: Develop an overall plan for the analysis based on stock-by-stock review of the data provided.
- Step 3: Pre-screen model forms *without* environmental covariates using the forecastr App
- Step 4: Pre-screen environmental covariates and reorganize candidate variables into forecastR format
- Step 5: Pre-Screen model forms *with* environmental covariates using the forecastr App 
- Step 6: Run full suite of candidate models for all stocks using the forecastR package
- Step 7: Select 2025 forecast to submit for each of the 14 sockeye stocks
- Step 8: Lessons learned


[This repo](https://github.com/SOLV-Code/Team-forecastR-2025SockeyeInternational) has detailed documentation for each step. [This Readme](https://github.com/SOLV-Code/Team-forecastR-2025SockeyeInternational/tree/main/NOTES/7_Select_2025FC) lists the top-ranked models by stock and age class, shows the resulting 2025 forecasts, and shows retrospective diagnostics.


## Results

TBI




## Lessons Learned / Questions for Next Round



### Maybe sibling regressions just are less useful for sockeye than for Chinook, given that a single age class is typically the bulk of the sockeye return?


*  The agency forecast does not use sibling regression to predict the main age class (age 4 as a function of age 3 last year) for the 5 Fraser sockeye stocks in the competition. They do use sibling regression for the typically small component of age 5 returns (i.e., last year's return of the main age class as a predictor for the older returns from the same cohort this year).

* **CHECK if any Bristol Bay agency forecasts use sib reg**

* Current suite of *forecastR* model forms developed to address Chinook Tech Comm needs. Next round of work will build an option to load custom model forms and test against built-in models. Test cases for custom model form will include spawner-recruit models. We'll see if those do any better...


### So why did sibling regressions tend to come out as top-ranked in the model selection workflow with *forecastR*? 

* Need to revisit the rationale for model selection in sockeye applications, based on analyses of 2025 results across team entries. 


### Maybe sockeye returns (or all salmon?) have become so variable due to yet-to-be identified background variables that retrospective performance over the last few years just isn't a useful selection criterion anymore?

Only three of the teams submitted retrospective results. This did not give a large enough sample to detect any meaningful relationship between team rank in the retrospective vs. team rank in the 2025 predictions. However, looking at stock-specifc results for those 3 teams:

- There is a strong relationship between better retrospective performance and a closer forecast for 2025, when looking only at those cases where absolute percent error is less than 100% (right panel). 

- There are some large exceptions to this relationship (left panel). 
   - Two Quesnel forecasts have a similarly large error in the retrospective, but one produced a 2025 forecast that was pretty close, and the other was way off. Need to look at the model forms to check if there's any clue to potential mechanism.
   - Three cases had low error in the retrospective but large error in 2025 forecast. What was the model structure and what mechanism did that miss?


 <img src="https://github.com/SOLV-Code/SalmonPrize_Diagnostics/blob/main/Sockeye_International_2025/Diagnostics/COMPARISON_ByStock_RetroVsFC_Plots.png" width="800">


### Is the percent error performance measure introducing a selection bias towards underestimates when dealing with the kinds of very large percent errors encountered in sockeye forecasting?

A forecast coming in at double observed has APE = 100%, and a forecast coming in at half observed has APE= 50%, but they are both off by a factor of 2. The larger the error, the more pronounced the difference in APE between over and under-prediction errors with the same order of magnitude. A 10 times over-prediction results in APE =900%, but a forecast at 1/10th of observed has APE = 90%.

Figure below illustrates the issue for a stock with observed run = 4 million (like Chilko in 2025) and forecasts ranging from 400,000 (1/10th of observed) to 40 million (10 x observed).


 <img src="https://github.com/SOLV-Code/SalmonPrize_Diagnostics/blob/main/Sockeye_International_2025/Diagnostics/PercentError_Properties.png" width="800">

























