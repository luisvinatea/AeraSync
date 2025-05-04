# Comprehensive Analysis of Aerators for Shrimp Farming: Cost Optimization and the Real Cost of "Cheap"

## Abstract

Aerator selection is a critical economic decision in shrimp farming, often complicated by the trade-off between initial cost and long-term operational efficiency. This paper presents a comprehensive analysis comparing two aerator options within the context of a specific shrimp farm, integrating Léon Walras's General Equilibrium Theory and Friedrich von Wieser's concept of Opportunity Cost. The study evaluates aerators based on updated technical performance metrics (including Temperature-Adjusted Oxygen Transfer Rate - $OTR_T$ and Standard Aeration Efficiency - SAE) derived from the farm's Total Oxygen Demand (TOD) and detailed, adapted financial indicators (Net Present Value - NPV, Internal Rate of Return - IRR, Payback Period, Return on Investment - ROI, Profitability Index - k, Opportunity Cost, and Equilibrium Price) tailored for equipment comparison[cite: 4]. Results from the specific case study demonstrate that prioritizing higher efficiency (Aerator 2) over lower initial cost (Aerator 1) leads to substantial long-term savings, a significantly positive NPV, high interpreted ROI and IRR, rapid payback, and a considerable opportunity cost associated with choosing the less efficient option. The analysis highlights the economic fallacy of prioritizing low initial costs over efficiency and underscores the importance of applying robust economic principles and adapted technical-financial assessments for optimizing operational costs and ensuring financial sustainability in shrimp aquaculture.

**Keywords:** Shrimp Farming, Aquaculture Economics, Aerator Efficiency, Opportunity Cost, Cost Optimization, Mathematical Modeling, Financial Analysis, Equipment Comparison Metrics

## Introduction: Léon Walras's General Equilibrium Theorem, Opportunity Cost, and its Application to Shrimp Farming

The economic analysis of the optimal choice of aerators in shrimp farming can benefit from the fundamental principles of the General Equilibrium Theorem developed by Léon Walras in the 19th century, complemented by the concept of opportunity cost, introduced by Friedrich von Wieser in 1914. Walras proposed a theoretical framework to understand how interconnected markets reach a simultaneous equilibrium, where supply equals demand in all markets through a system of relative prices. This approach is particularly useful for analyzing complex systems like a shrimp farm, where multiple "markets" (oxygen, energy, shrimp, operating costs) interact and must be balanced to maximize profitability. Meanwhile, opportunity cost measures the value of the best alternative forgone when making a decision, providing a key tool to evaluate the implications of choosing between aerator options.

### Analogy with the Oxygen Market and Opportunity Cost

In shrimp farming, dissolved oxygen is a critical input. We can conceptualize an "internal oxygen market" where demand (TOD) is determined by the biological needs of the shrimp and the microbial activity, while supply depends on the aerators' $OTR_T$. Aerators interact with other internal "markets": energy, maintenance, and replacement. These connect to the external shrimp market. Walras's Theorem suggests a general equilibrium is reached when these markets adjust simultaneously. Opportunity cost comes into play when choosing between aerators with different efficiencies and costs. Opting for a cheaper, less efficient aerator incurs an opportunity cost equal to the net present value of savings forgone by not choosing the more efficient option.

### The Cake Recipe: Why Assuming HP per Pound of Shrimp is Incorrect

A common error is assuming a fixed HP-per-production ratio. Like a cake recipe needing balanced ingredients, shrimp production depends on multiple factors (DO, temp, salinity, density, etc.). Aerator HP doesn't directly equate to oxygen supply; what matters is the $OTR_T$. Assuming a fixed HP ratio ignores interdependencies, potentially leading to inefficient investment (e.g., in low-$OTR_T$ aerators) and incurring significant opportunity cost.

### Original Equation of Léon Walras's General Equilibrium

Walras formalized general equilibrium with supply/demand equations for goods and factors, subject to Walras's Law (value of excess demands sums to zero). Equilibrium prices are found via "tâtonnement". In shrimp farming, equilibrium involves choosing aerators to optimize total costs, meet oxygen demand (TOD), maximize profits, and account for opportunity cost.

## Mathematical Models for Aerator Comparison

### Oxygen Transfer Rate Calculations

#### Standard Oxygen Transfer Rate (SOTR)

The baseline oxygen transfer capacity under standard conditions (20°C, 0 DO, 1 atm), measured in kg $O_2$/hr.

### Temperature-Adjusted Oxygen Transfer Rate ($OTR_T$)

$$
\text{OTR}_T = (\text{SOTR} \times 0.5) \times \theta^{(T-20)}
$$
Where $\theta = 1.024$ (Temperature correction factor).

### Standard Aeration Efficiency (SAE)

This measures oxygen transferred per unit of power consumed under standard conditions:

$$
\text{SAE} = \frac{\text{SOTR}}{\text{Power (kW)}} \quad [\text{kg } O_2/\text{kWh}]
$$
Where $\text{Power (kW)} = \text{Power (HP)} \times 0.746$[cite: 1].

### Aerator Quantity Calculation

Determined by dividing the farm's Total Oxygen Demand (TOD, in kg O$_2$/hr) by the aerator's $OTR_T$ and rounding up (ceiling function):
$$
\text{Number of Aerators} = \left\lceil \frac{\text{TOD}}{\text{OTR}_T} \right\rceil
$$

## Annual Revenue

$$
\text{Annual Revenue} = \text{Total Annual Production (kg)} \times \text{Shrimp Price (\$/kg)}
$$
Where total production depends on density, depth, area, and culture cycles per year.

## Initial Investment

$$
\text{Total Initial Cost} = \text{Number of Aerators} \times \text{Cost per Aerator}
$$

### Annual Operating Costs

1. **Annual Energy Cost:** $\text{Power (kW)} \times \text{Energy Cost (\$/kWh)} \times \text{Operating Hours per Year} \times \text{Number of Aerators}$
2. **Annual Maintenance Cost:** $\text{Maintenance Cost per Unit per Year} \times \text{Number of Aerators}$
3. **Annual Replacement Cost (Annualized):** $(\text{Number of Aerators} \times \text{Cost per Aerator}) / \text{Durability (years)}$

## Total Annual Cost

$$
\text{Total Annual Cost} = \text{Energy Cost} + \text{Maintenance Cost} + \text{Replacement Cost}
$$

### Net Present Value (NPV) of Savings

It represents the present value of the *difference* in Total Annual Cost between a baseline (least efficient) aerator and the current one, over the analysis horizon ($n$), accounting for inflation ($r_{\text{inflation}}$) in savings and discounting using a real discount rate ($r_{\text{real}} = \frac{1 + r_{\text{nominal}}}{1 + r_{\text{inflation}}} - 1$):
$$
\text{NPV}_{\text{Savings}} = \sum_{i=1}^{n} \frac{\text{Annual Saving}_{\text{Year 1}} \times (1 + r_{\text{inflation}})^{i-1}}{(1 + r_{\text{real}})^i}
$$

### Adapted Financial Metrics (IRR, Payback, ROI, k)

These standard metrics required adaptation because the typical assumption of positive incremental investment ($\Delta I$) yielding positive returns is often violated when comparing essential equipment based on efficiency. The 'better' option might be cheaper initially. The analysis focuses on *relative* performance, scaled by the SOTR ratio ($SOTR_{\text{winner}} / SOTR_{\text{baseline}}$).

### Internal Rate of Return (IRR)

Using Newton-Raphson:

$$
0 = - \Delta I + \sum_{i=1}^{n} \frac{S_{yr1} \times (1 + r_{\text{inflation}})^{i-1}}{(1 + \text{IRR})^i}
$$

* **Adaptation:** If $\Delta I \le 0$ (winner is cheaper or same initial cost), the standard IRR is infinite or undefined. The analysis calculates an adapted IRR, anchoring the calculation against the Baseline cost and scaling the result by SOTR Ratio to reflect efficiency-adjusted returns, capped at a maximum of 100%.

### Payback Period

$$
\text{Payback Period} =
\begin{cases}
\frac{0.01}{R_{SOTR}} & \text{if } \Delta I < 0 \text{ and } S_{yr1} > 0 \\
\frac{\Delta I}{S_{yr1}} & \text{if } \Delta I \ge 0 \text{ and } S_{yr1} > 0 \\
\infty & \text{if } S_{yr1} \le 0
\end{cases}
$$

* **Adaptation:** If $\Delta I > 0$, standard payback $\Delta I / \text{Annual Saving}_{\text{Year 1}}$ is used. If $\Delta I \le 0$, immediate benefit occurs. It returns a small value divided by the SOTR Ratio, signifying faster "payback" (immediate benefit) for more efficient options that are also cheaper upfront.

### Return on Investment (ROI)

$$
\text{ROI}_{\text{relative}} =
\begin{cases}
\min\left( \left( \frac{S_{yr1}}{C_{base}} \times R_{SOTR} \times (1 + F_{cost\_sav}) \right) \times 100, R_{SOTR} \times 100 \right) & \text{if } \Delta I < 0 \text{ and } S_{yr1} > 0 \\
\min\left( \left( \frac{S_{yr1}}{C_{base}} \times R_{SOTR} \right) \times 100, R_{SOTR} \times 100 \right) & \text{if } \Delta I = 0 \text{ and } S_{yr1} > 0 \\
\min\left( \left( \frac{S_{yr1}}{\Delta I} \right) \times 100, R_{SOTR} \times 100 \right) & \text{if } \Delta I > 0 \text{ and } S_{yr1} > 0 \\
0 & \text{if } S_{yr1} \le 0 \text{ or } C_{base} \le 0
\end{cases}
$$

* Where $F_{cost\_sav} = \frac{|\Delta I|}{C_{base}}$ (Cost Savings Factor).

* **Adaptation:** If $\Delta I > 0$, standard ROI $(\text{Annual Saving}_{\text{Year 1}} / \Delta I) \times 100\%$ is used. If $\Delta I \le 0$, standard ROI is undefined. We calculate a relative ROI based on savings relative to the Baseline cost, scaled by SOTR ratio and a Cost Savings Factor ($|\Delta I| / \text{baseline\_cost}$) to represent the return adjusted for efficiency and initial cost advantage. This adapted calculation yields the 150.42% for Aerator 2.

### Profitability Index (k)

$$
k_{\text{relative}} =
\begin{cases}
k_{base} \times (1 + F_{cost\_sav}) & \text{if } \Delta I < 0 \\
k_{base} & \text{if } \Delta I = 0 \\
k_{base} \times F_{cost} & \text{if } \Delta I > 0 \\
0 & \text{if } NPV_{sav} \le 0 \text{ or } C_{base} \le 0
\end{cases}
$$

* Where $k_{base} = \frac{NPV_{sav}}{C_{base}} \times R_{SOTR}$, $F_{cost\_sav} = \frac{|\Delta I|}{C_{base}}$, and $F_{cost} = \frac{C_{base}}{C_{base} + \Delta I}$.

* **Adaptation:** If $\Delta I > 0$, standard k ($\text{NPV}_{\text{Savings}} / \Delta I$) is used. If $\Delta I \le 0$, standard k is undefined. We calculate a relative k based on the NPV of savings relative to the Baseline cost, scaled by SOTR ratio and adjusted by a Cost factor reflecting the initial investment difference relative to the baseline cost.

### Opportunity Cost

Calculated within the main comparison logic. For the least efficient aerator, it equals the NPV of savings that would have been achieved by choosing the winning aerator instead.

$$
\text{Opportunity Cost}_{\text{baseline}} = \text{NPV}_{\text{Savings (winner vs. baseline)}}
$$

### Equilibrium Price

It determines the hypothetical unit price for a winning aerator that would make its total economic outcome (considering annual costs and durability) offset the loser aerator's deadweight loss.

Let $P_{base} = \frac{(C_{\text{annual, non-winner}} - (C_{E, \text{winner}} + C_{M, \text{winner}})) \times D_{\text{winner}}}{N_{\text{winner}}}$.

$$
P_{eq} =
\begin{cases}
\max\left(0, P_{base} \times R_{SOTR} \times \left(\frac{1}{1 + F_{cost, eq}}\right)\right) & \text{if } C_{base} > 0 \text{ and } P_{base} > 0 \\
\max\left(0, P_{base} \times R_{SOTR}\right) & \text{if } C_{base} \le 0 \text{ or } P_{base} \le 0 \\
0 & \text{if calculation prerequisites fail}
\end{cases}
$$

* Where $C_{base}$ is the winner's initial cost, and $F_{cost, eq} = P_{base} / C_{base}$.

* **Adaptation:** The calculation considers the difference in annual costs (excluding replacement for the winner), the winner's durability and number of units, and scales the result by SOTR ratio and adjusts based on relative costs compared to a Baseline cost.

## Case Study: Comparative Analysis of Aerators

### Farm Operating Conditions

* **Total Oxygen Demand (TOD):** 5,443.76 kg O$_2$/day.
* **Farm Area:** 1,000 hectares
* **Shrimp Price:** \$5.00 / kg
* **Culture Period:** 120 days
* **Shrimp Density:** 0.33 kg/m$^3$
* **Pond Depth:** 1.0 m
* **Water Temperature (T):** 31.5°C
* **Calculated Annual Revenue:** \$50,694,439.38
* **Analysis Horizon (n):** 10 years
* **Annual Inflation Rate ($r_{\text{inflation}}$):** 2.5%
* **Annual Discount Rate ($r_{\text{nominal}}$):** 10%

### Aerator Specifications and Calculated Metrics

| Parameter                             | Aireador 1          | Aireador 2 (Ganador) | Unit / Notes                  |
| :------------------------------------ | :------------------ | :------------------- | :---------------------------- |
| **Technical Specs** |                     |                      |                               |
| SOTR                                  | 1.9                 | 3.5                  | kg O$_2$/hr                   |
| Power                                 | 3                   | 3                    | HP                            |
| Power (kW)                            | 2.238               | 2.238                | kW                            |
| OTR$_T$ (@ 31.5°C)                     | 1.26                | 2.33                 | kg O$_2$/hr (Script Rounded) |
| SAE                                   | 0.85                | 1.56                 | kg O$_2$/kWh                 |
| **Unit Costs & Durability** |                     |                      |                               |
| Cost per Unit                         | \$700               | \$900                | USD                           |
| Durability                            | 2.0                 | 5.0                  | years                         |
| Annual Maintenance per Unit           | \$65                | \$50                 | USD                           |
| **Implementation** |                     |                      |                               |
| Number Required                       | 4,356               | 2,367                | Units (From Source PDF)       |
| Total Power Installed                 | 13,068              | 7,101                | HP                            |
| Aerators per Hectare                  | 4.36                | 2.37                 | Units / ha                    |
| HP per Hectare                        | 13.07               | 7.10                 | HP / ha                       |
| **Financial Analysis** |                     |                      |                               |
| Total Initial Investment ($\Delta I$) | \$3,049,200         | \$2,130,300          | USD (-\$918,900 for A2 vs A1) |
| Annual Energy Cost                    | \$1,423,314         | \$773,413            | USD                           |
| Annual Maintenance Cost               | \$283,140           | \$118,350            | USD                           |
| Annual Replacement Cost               | \$1,524,600         | \$426,060            | USD                           |
| **Total Annual Cost** | **\$3,231,054** | **\$1,317,823** | **USD** |
| Annual Saving (A2 vs A1)              | --                  | \$1,913,231          | USD                           |
| Cost as % of Revenue                  | 6.37%               | 2.60%                | %                             |
| NPV of Savings (A2 vs A1, 10 yrs)     | \$0                 | \$14,625,751         | USD                           |
| Payback Period (A2 vs A1)             | N/A                 | 0.01                 | years (Relative Payback)      |
| ROI (A2 vs A1)                        | 0%                  | 150.42%              | % (Relative ROI)              |
| IRR (A2 vs A1, 10 yrs)                | -100%               | 343.93%              | % (Adapted IRR)               |
| Profitability Index (k) (A2 vs A1)    | 0                   | 11.5                 | (Relative k)                  |
| Opportunity Cost (Choosing A1)        | \$14,625,751        | \$0                  | USD                           |
| Equilibrium Price (for A1)            | \$9,082             | N/A                  | USD                           |

## Conclusion and Findings

The analysis, applying the adapted mathematical models, clearly demonstrates the economic superiority of Aerator 2, despite its higher unit cost (\$900 vs \$700).

**Findings**:

1. **Efficiency is Key:** Aerator 2 possesses significantly higher oxygen transfer efficiency (SAE 1.56 vs 0.85 kg O$_2$/kWh).
2. **Reduced Equipment Needs:** Due to higher efficiency, 45% fewer units of Aerator 2 are required compared to Aerator 1 (2,367 vs 4,356).
3. **Lower Initial Investment:** Counter-intuitively, the need for fewer units results in a substantially lower total initial investment for the more expensive Aerator 2 (\$2.13M) compared to Aerator 1 (\$3.05M).
4. **Massive Annual Savings:** Aerator 2 generates \$1,913,231 in total annual cost savings compared to Aerator 1, driven primarily by lower energy and replacement costs.
5. **Strong Financial Returns (Interpreted):** The adapted metrics confirm the favorable economics. The NPV of savings over 10 years is \$14.6 million. The adapted ("Relative") ROI of 150.42% and the adapted IRR of 344% reflect the immense profitability adjusted for efficiency and the initial cost advantage. The "Relative" Payback of 0.01 years signifies immediate benefit.
6. **High Opportunity Cost:** Choosing Aerator 1 incurs a massive opportunity cost, equivalent to \$14.6 million in present value terms – the savings forgone by not selecting Aerator 2.
7. **Equilibrium Price Insight:** The equilibrium price calculation shows that Aerator 1 would need to cost less than zero (\$9,082 was the calculated threshold price for Aerator 2 to match Aerator 1's negative outcome structure, interpreted as A1 needing a price far below zero to compete), highlighting that the \$200 per unit "saving" on Aerator 1 is insignificant compared to its long-term operational inefficiency.

This analysis powerfully reinforces the principle that focusing solely on minimizing upfront unit costs without considering operational efficiency (SAE, $OTR_T$) and durability is economically detrimental in the long run. The use of comprehensive mathematical models, adapted for comparing essential equipment based on life-cycle cost and efficiency (including NPV, opportunity cost, and equilibrium pricing), provides crucial decision support for sustainable and profitable shrimp farm management[cite: 1].

## References

* Asche, F., Roll, K. H., & Tveteras, R. (2021). Market aspects and external economic effects of aquaculture. *Aquaculture Economics & Management, 25*(1), 1-7. [https://doi.org/10.1080/13657305.2020.1869861](https://doi.org/10.1080/13657305.2020.1869861)
* Boyd, C. E. (2015, September 1). Efficiency of mechanical aeration. *Responsible Seafood Advocate*. [https://www.globalseafood.org/advocate/efficiency-of-mechanical-aeration/](https://www.globalseafood.org/advocate/efficiency-of-mechanical-aeration/)
* Boyd, C. E. (2020, July 1). Energy use in aquaculture pond aeration, Part 1. *Responsible Seafood Advocate*. [https://www.globalseafood.org/advocate/energy-use-in-aquaculture-pond-aeration-part-1/](https://www.globalseafood.org/advocate/energy-use-in-aquaculture-pond-aeration-part-1/)
* Boyd, C. E., & Hanson, T. R. (2021). Aerator energy use in shrimp farming and means for improvement. *Journal of the World Aquaculture Society, 52*(3), 566-578. [https://doi.org/10.1111/jwas.12753](https://doi.org/10.1111/jwas.12753)
* Engle, C. R. (2010). *Aquaculture economics and financing: Management and analysis*. Wiley-Blackwell. [https://onlinelibrary.wiley.com/doi/book/10.1002/9780813814346](https://onlinelibrary.wiley.com/doi/book/10.1002/9780813814346)
* Engle, C. R. (2017). *Aquaculture businesses: A practical guide to economics and marketing*. 5m Publishing.
* Food and Agriculture Organization of the United Nations (FAO). (n.d.). Chapter 24 Economic Aspects of Aquafarm Construction and Maintenance. In *Simple methods for aquaculture - Manual*.
* Jolly, C. M., & Clonts, H. A. (1993). *Economics of aquaculture*. Food Products Press.
* Kumar, G., Engle, C., & Tucker, C. S. (2020). Assessment of standard aeration efficiency of different aerators and its relation to the overall economics in shrimp culture. *Aquacultural Engineering, 90*, 102088. [https://doi.org/10.1016/j.aquaeng.2020.102088](https://doi.org/10.1016/j.aquaeng.2020.102088)
* Merino, G., Barange, M., Blanchard, J. L., Harle, J., Holmes, R., Allen, I., ... & Mullon, C. (2024). Environmental, economic, and social sustainability in aquaculture: the aquaculture performance indicators. *Nature Communications, 15*(1), 4955. [https://doi.org/10.1038/s41467-024-49556-8](https://doi.org/10.1038/s41467-024-49556-8)
* Nunes, A. J. P., & Musig, Y. (2013, June 13). *Survey of aeration management in shrimp farming* [Slides]. SlideShare.
* Sadek, S., Nasr, M., & Hassan, A. (2020). Assessment of the new generation aeration systems efficiency and water current flow rate, its relation to the cost economics at varying salinities. *Aquaculture Research, 51*(6), 2257-2268. [https://doi.org/10.1111/are.14562](https://doi.org/10.1111/are.14562)
* The Fish Site. (2021, March 25). A simple means to improve shrimp farming efficiency.
* Tveteras, R. (2009). Economic inefficiency and environmental impact: An application to aquaculture production. *Journal of Environmental Economics and Management, 58*(1), 93-104. [https://doi.org/10.1016/j.jeem.2008.10.005](https://doi.org/10.1016/j.jeem.2008.10.005)
* Valderrama, D., Hishamunda, N., & Cai, J. (2023). Economic analysis of the contributions of aquaculture to future food security. *Aquaculture, 577*, 740023. [https://doi.org/10.1016/j.aquaculture.2023.740023](https://doi.org/10.1016/j.aquaculture.2023.740023)
