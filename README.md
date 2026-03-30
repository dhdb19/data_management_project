

 ## Motivation and research question

The rise of far right populist parties and their increasingly aggressive anti-immigration rhetoric and policies only continues to gain in prescience. There are several strands of research examining individuals' anti-immigration attitudes among the public. One explanatory approach is proximity or exposure to immigrants in one's life. Another approach looks at far right populist parties' electoral success as the dependent variable.

Dustman et al. (2018) summarize two competing hypotheses in this vein: Conflict theory (LeVine & Campbell, 1972) predicts resident immigrant share will negatively affect individuals' attitudes towards immigrant, while the contact hypothesis suggest it will lead to more generous attitudes by reducing stereotype and prejudice (Allport, 1979).

Recently there has been push toward more experimental field research at the local level, e.g. impact of new refugee centers (e.g. Bratti et al., 2020). 

For a meta-analysis on the topic see Cools et al. (2021). Findings suggest there is still more room for exploration of the question, *how does local immigration affect individuals' attitudes towards immigration?*

I find these insight from hyperlocal field-experiments, e.g. Enos (2014), particularly interesting, as this type of data is of course very difficult to collect. While the local approach lends results greater internal validity when it comes to examining the actual individual degree of immigrant contact among respondents, external validity is limited due to the local geographic scope. In the light of this I attempted to make use of the publically available demograhpic data of Europe's statistical agency to approximate the local approach at a more macro level.

## Data

To answer my research question I used individual-level survey data in the from of the European Social Survey to gauge individuals immigration attitudes. I used the 2011 and 2021 European censuses to establish the share of immigrants of the total population in a region as the operationalization of immigrant proximity.

As determined by the timing of the census I used the 6th (European Social Survey European Research Infrastructure (ESS ERIC), 2025) and 10th wave of the ESS (European Social Survey European Research Infrastructure (ESS ERIC), 2023). 

The 2021 census divides the European continent into 1km × 1km cells and reports population for those grid, most importantly total population, population not born in the country of residence (Geographic Information System of the Commission, 2025). Similar grid data is available for the 2011 census, however, Eurostat already provides the aggregated data at the NUTS 3 level (Nomenclature of territorial units for statistics), with level 3 being the most local NUTS classification, e.g. corresponding in Germany mostly to counties (Landkreise). This was not the case for the 2021 census data, so I merged it with the publicly available geographic NUTS data (Geographic Information System of the Commission, n.d.).

I have prepared the data such that an analysis of independent variable could be conducted at any of the three NUTS levels, mostly because, while the ESS does report respondents' NUTS region for the most part, it varies from country to country at what level. A sizeable proportion of observations is at the most local level, NUTS 3, but this limits the number of countries included in the analysis significantly.

To summarize, the final analysis dataset allows different types of analyses. Within one ESS round it allows for cross-sectional bi-variate analysis of individuals local resident immigrant share across many European countries at different levels of locality. 

The 2011 census cannot be downloaded from a single link, because it is configured via a dataset builder (Eurostat, n.d.). Under Data sets select Census 2011 from the dropdown, then from the list CensusHub domain category scheme -> Geography: Nation + Regions NUTS 1, 2, 3 -> Population overview -> Country of birth, Citizenship, Residence one year prior to census, Marital Status. In the following file builder check all countries and NUTS regions in the GEO tab, in the POB tab check Place of Birth in reporting country, Place of birth not in reporting country, Other and Unknown (not Total!). In all other tabs only check Total.

For the geometric NUTS data I used the 2021 NUTS data in the GeoPackage format, polygon geometry and scale of 60m and EPSG:3035 coordinate system (Geographic Information System of the Commission, n.d.).

Using the ESS datafile builder I compiled datasets containing the relevant rotating module on immigration and the region data.


## Bibliography


Allport, G. W. (1979). *The Nature of Prejudice: 25th Anniversary Edition*. Basic Books.

Bratti, M., Deiana, C., Havari, E., Mazzarella, G. & Meroni, E. C. (2020). Geographical proximity to refugee reception centres and voting. *Journal Of Urban Economics, 120*, 103290. https://doi.org/10.1016/j.jue.2020.103290

Cools, S., Finseraas, H. & Rogeberg, O. (2021). Local Immigration and Support for Anti‐Immigration Parties: A Meta‐Analysis. *American Journal Of Political Science, 65*(4), 988–1006. https://doi.org/10.1111/ajps.12613

Dustmann, C., Vasiljeva, K. & Damm, A. P. (2018). Refugee Migration and Electoral Outcomes. *The Review Of Economic Studies, 86(5)*, 2035–2091. https://doi.org/10.1093/restud/rdy047

Enos, R. D. (2014). Causal effect of intergroup contact on exclusionary attitudes. *Proceedings Of The National Academy Of Sciences, 111*(10), 3699–3704. https://doi.org/10.1073/pnas.1317670111

European Social Survey European Research Infrastructure (ESS ERIC) (2025). *ESS round 6 - 2012: Personal wellbeing, Democracy* [Dataset]. Sikt - Norwegian Agency for Shared Services in Education and Research. https://doi.org/10.21338/NSD-ESS6-2012.

European Social Survey European Research Infrastructure (ESS ERIC) (2023) *ESS round 10 - 2020: Democracy, Digital social contacts* [Dataset]. Sikt - Norwegian Agency for Shared Services in Education and Research. https://doi.org/10.21338/NSD-ESS10-2020.

Eurostat (n.d.). CensusHub. European Commission. https://ec.europa.eu/CensusHub/selectHyperCube?clearSession=true

Geographic Information System of the Commission (n. d.). *Territorial units for statistics (NUTS)* [Dataset]. European Commission. https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics

Geographic Information System of the Commission (2025, January 22). *Census population grid* [Dataset]. European Commission. https://ec.europa.eu/eurostat/web/gisco/geodata/population-distribution/population-grids

LeVine, R. A. & Campbell, D. T. (1972). *Ethnocentrism: Theories of Conflict, Ethnic Attitudes, and Group Behavior*. John Wiley & Sons.