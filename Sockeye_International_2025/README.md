# 2025 Sockeye International


## Key Links

* [Competition Main Page](https://salmonprize.com/competitions/2025-sockeye-international) 
* [Data File](https://drive.google.com/file/d/1nnrJ-KpP_WdsY-zC775Oy2FDSJXscSgP/view?usp=sharing)
* [Available Prizes](https://salmonprize.com/competitions/2025-sockeye-international)


## Overview

* The challenge: 2025 run size forecasts for 14 sockeye stocks from Bristol Bay in Alaska (8 stocks), the Fraser River in British Columbia (5 stocks), and the Columbia River in Washington (1 stock aggregate).
* 10 teams submitted forecasts for 2025. 3 of the teams (**VERIFY WITH THE TEAMS!**) submitted retrospective forecasts for earlier years. The [Team Submissions folder](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Team_Submissions) has one directory for each team, containing *predictions.csv'* and , where available *retrospective.csv*, as well as model descriptions and any code or supplementary materials submitted. It also has an [evolving metadata file]() where we've started to categorize the diversity of competing models as a step towards future meta-analyses.
* [Observed Runs](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Observed_Runs) and [agency forecasts with method descriptions](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/AgencyFC) have also been compiled. 



## Diagnostics (**DRAFT**)

**NOTE**: Fraser sockeye run size estimates are not yet final. These diagnostics are based on the currently available estimates, and will be updated when run size estimates are finalized. ETA for final numbers is May 2026.

*Full set of diagnostics available [here](https://github.com/SOLV-Code/SalmonPrize_Diagnostics/tree/main/Sockeye_International_2025/Diagnostics)*

Some observations:

- 21 prizes vs 10 teams -> pretty good odds :-)
- Avg error across 14 stocks = more than 1Mill (Best team: 1.2 Mill, largest avg error= 2.2Mill)
- Avg error across stocks in the system:
   * All teams underestimated Fraser by a lot
   * 9 of 10 teams over-estimated Columbia River
   * Mixed Bag of over/under for Bristol Bay
- How Agency FC did compared to competitors (using MAPE)
   * Overall 3rd
   * Bristol Bay 1st
   * Fraser 3rd
   * Columbia 8th
- Rankings highly sensitive to choice of performance measure
(e.g. agency FC 1st for Bristol Bay with MAPE, but 7th with MPE)
