# 2025 Sockeye International


## Key Links

* [Competition Main Page](https://salmonprize.com/competitions/2025-sockeye-international) 
* [Data File](https://drive.google.com/file/d/1nnrJ-KpP_WdsY-zC775Oy2FDSJXscSgP/view?usp=sharing)
* [Available Prizes](https://salmonprize.com/competitions/2025-sockeye-international)


## Overview

* The challenge: 2025 run size forecasts for 14 sockeye stocks from Bristol Bay in Alaska (8 stocks), the Fraser River in British Columbia (5 stocks), and the Columbia River in Washington (1 stock aggregate).
* 10 teams submitted forecasts for 2025. 3 of the teams submitted retrospective forecasts for 2020-2024. The [Team Submissions folder](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Team_Submissions) has one directory for each team, containing *predictions.csv* and , where available *retrospective.csv*, as well as model descriptions. Some teams also submitted code and supplementary materials, but these additional files are not currently included in their team submission folder. Teams can add any supplementary files or include links to more information in the Readme for their contribution. 
* The Team Submissions folder also has an [evolving metadata file](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/blob/main/Sockeye_International_2025/Team_Submissions/Sockeye_International_2025_ModelMetadata.csv) where we've started to categorize the diversity of competing models as a step towards future meta-analyses.
* [Observed Runs](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Observed_Runs) and [agency forecasts with method descriptions](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/AgencyFC) have also been compiled. Method descriptions for the agency forecasts use the same (evolving) set of metadata fields as the team submission metadata file.



## Diagnostics (**DRAFT**)

### Overview of Available Diagnostics

**NOTE**: Fraser sockeye run size estimates are not yet final. These diagnostics are based on the currently available estimates, and will be updated when run size estimates are finalized. ETA for final numbers is May 2026, but we don't expect any changes to be large enough to affect team rankings at the aggregate level (Lowest MAPE for Fraser, Lowest MAPE overall).

* Full set of overall diagnostic plots and summary tables (in csv format) available [here](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Diagnostics). These include plots of MAPE and MPE by system (Bristol Bay, Fraser, Columbia) and by stock, showing the distribution of team forecasts compared to the official agency forecast.

* Team-specific diagnostic plots for each stock  are in the *DiagnosticPlots* folder within each team's folder (e.g., for [HookedOnData](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Team_Submissions/Hooked%20On%20Data/DiagnosticPlots)). These plots show observed returns, the team's forecast for 2025, the agency forecast for 2025, and all the other team forecasts for comparison. Where available, the plots also include brief descriptions of the team's model and the agency forecast method, pulled from the metadata files.

* Teams can use the *README.md* file in their team folder to compile thoughts on the 2025 competition and explore some follow-up analyses. To get started with editing these files, see [this quick explanation of approaches](https://stackoverflow.com/a/72175776) and  [this formatting cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet). The [README for Team Salmon ForecastR](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Team_Submissions/Salmon%20ForecastR) is an example providing more background about the team's approach and exploring some questions that arose from the 2025 competition.


### Some High-level Observations

- 21 prizes vs 10 teams -> pretty good odds :-)

- Mean Absolute Error (MAE) across 14 stocks = more than 1Mill (Best team: 1.2 Mill, largest avg error= 2.2Mill)

- Avg error across stocks in the system:
   * All teams underestimated Fraser by a lot
   * 9 of 10 teams over-estimated Columbia River
   * Mixed Bag of over/under for Bristol Bay

- Comparing Systems:
   * Mean Absolute Percent Error (MAPE) of winning team ca. 3 times larger for Fraser than for Bristol Bay
   * MAPE for Columbia is not comparable, because only 1 stock aggregate being predicted.

- How did the official agency forecast perform compared to competitors? (using MAPE)
   * Overall: 3rd
   * Bristol: Bay 1st
   * Fraser: 3rd
   * Columbia: 8th

- How would an ensemble forecast combining all team predictions have performed compared to agency forecast?
   * Overall: Ensemble Mean 4th and Median 6th vs. agency forecast in 2nd place
   * Bristol Bay: Ensemble Mean 2nd and median 6th vs. agency forecast in 1st place
   * Fraser: Ensemble Mean 6th and median 8th vs. agency forecast in 3rd place
   * Columbia: Ensemble Mean 8th and median 6th vs. agency forecast in 7th place

- Rankings highly sensitive to choice of performance measure
(e.g. agency FC 1st for Bristol Bay with MAPE, but 7th with MPE)
