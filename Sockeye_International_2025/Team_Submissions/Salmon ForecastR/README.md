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


