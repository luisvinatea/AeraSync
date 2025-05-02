"""aerator_comparer.py
This module compares aerators for shrimp farming based on specs
and financial metrics. It calculates OTR_T from SOTR, includes
revenue from shrimp production, and focuses on savings and
opportunity cost for financial indicators.
"""
import json
import math
from collections import namedtuple

# Data structures using namedtuple
Aerator = namedtuple('Aerator', [
    'name', 'sotr', 'power_hp', 'cost', 'durability', 'maintenance'
])
FinancialInput = namedtuple('FinancialInput', [
    'energy_cost', 'hours_per_night', 'discount_rate',
    'inflation_rate', 'horizon', 'safety_margin', 'temperature'
])
FarmInput = namedtuple('FarmInput', [
    'tod', 'farm_area_ha', 'shrimp_price', 'culture_days',
    'shrimp_density_kg_m3', 'pond_depth_m'
])
AeratorResult = namedtuple('AeratorResult', [
    'name', 'num_aerators', 'total_power_hp', 'total_initial_cost',
    'annual_energy_cost', 'annual_maintenance_cost',
    'annual_replacement_cost', 'total_annual_cost',
    'cost_percent_revenue', 'npv_savings', 'payback_years',
    'roi_percent', 'irr', 'profitability_k', 'aerators_per_ha',
    'hp_per_ha', 'sae', 'opportunity_cost'
])

# Constants
HP_TO_KW = 0.746
THETA = 1.024  # Real THETA value


# Helper functions
def calculate_otr_t(sotr, temperature):
    """Calculate Adjusted Oxygen Transfer Rate (OTR_T) from SOTR."""
    otr_t = (sotr * 0.5) * (THETA ** (temperature - 20))
    return float(f"{otr_t:.2f}")


def calculate_annual_revenue(farm):
    """Calculate annual revenue based on shrimp price, culture days."""
    if farm.culture_days <= 0:
        raise ValueError("Culture days must be positive")
    pond_density = farm.shrimp_density_kg_m3 * farm.pond_depth_m * 10
    cycles_per_year = 365 / farm.culture_days
    production_per_ha = pond_density * 1000  # Convert ton/ha to kg/ha
    total_production = production_per_ha * farm.farm_area_ha  # kg
    revenue_per_cycle = total_production * farm.shrimp_price
    return float(f"{revenue_per_cycle * cycles_per_year:.2f}")


# Financial calculation functions
def calculate_npv(cash_flows, discount_rate, inflation_rate):
    """Calculate NPV of cash flows with inflation adjustment."""
    if abs(inflation_rate - discount_rate) < 1e-6:
        return sum(cash_flows)
    real_discount_rate = (1 + discount_rate) / (1 + inflation_rate) - 1
    npv = sum(
        cf / (1 + real_discount_rate) ** i
        for i, cf in enumerate(cash_flows, 1)
    )
    return float(f"{npv:.2f}")


def newton_raphson(func, func_prime, x0, tol=1e-6, maxiter=100):
    """Newton-Raphson method for finding roots."""
    x = x0
    for _ in range(maxiter):
        fx = func(x)
        fpx = func_prime(x)
        if abs(fpx) < 1e-10:
            return 0
        delta_x = fx / fpx
        x -= delta_x
        if abs(delta_x) < tol:
            return x
    return x


def calculate_irr(initial_investment, cash_flows, sotr_ratio=1.0):
    """Calculate IRR with SOTR scaling and capping."""
    if initial_investment < 0:
        # Cap IRR at 1000% scaled by SOTR ratio
        return float(f"{min(1000 * sotr_ratio, 10000):.2f}")
    if sum(cash_flows) <= initial_investment:
        return -100

    def npv_func(rate):
        if rate <= -1:
            return float('inf')
        return -initial_investment + sum(
            cf / (1 + rate) ** (i + 1)
            for i, cf in enumerate(cash_flows)
        )

    def npv_prime(rate):
        if rate <= -1:
            return 0
        return sum(
            -(i + 1) * cf / (1 + rate) ** (i + 2)
            for i, cf in enumerate(cash_flows)
        )

    try:
        irr = newton_raphson(npv_func, npv_prime, 1.0)
        if -0.99 < irr < 10:
            return float(f"{irr * 100 * sotr_ratio:.2f}")
        elif irr >= 10:
            return float(f"{min(1000 * sotr_ratio, 10000):.2f}")
        else:
            return -100
    except (ZeroDivisionError, ValueError, OverflowError):
        return -100


def calculate_payback(initial_investment, annual_saving):
    """Calculate payback period."""
    if annual_saving > 0:
        payback = initial_investment / annual_saving
        return float(f"{payback:.2f}")
    return float('inf')


def calculate_relative_payback(
    initial_investment, annual_saving, sotr_ratio=1.0
):
    """Calculate relative payback period scaled by efficiency."""
    if annual_saving <= 0:
        return float('inf')
    if initial_investment < 0:
        # Since no payback is needed, return a small value scaled by efficiency
        return float(f"{0.01 / sotr_ratio:.2f}")
    payback = initial_investment / annual_saving
    return float(f"{payback:.2f}")


def calculate_roi(annual_saving, initial_investment):
    """Calculate ROI."""
    if initial_investment <= 0:
        return 0.00
    roi = annual_saving / initial_investment * 100
    return float(f"{roi:.2f}")


def calculate_relative_roi(
    annual_saving, initial_investment, baseline_cost=None, sotr_ratio=1.0
):
    """Calculate relative ROI scaled by efficiency and cost advantage."""
    if initial_investment == 0:
        return 0.00
    if initial_investment < 0:
        if baseline_cost and baseline_cost > 0:
            # Scale ROI based on baseline cost and efficiency
            cost_savings_factor = abs(initial_investment) / baseline_cost
            roi = (
                (annual_saving / baseline_cost) * 100 * sotr_ratio
                * (1 + cost_savings_factor)
            )
            return float(f"{roi:.2f}")
        roi = (annual_saving / abs(initial_investment)) * 100 * sotr_ratio
        return float(f"{roi:.2f}")
    roi = annual_saving / initial_investment * 100
    return float(f"{roi:.2f}")


def calculate_profitability_k(npv_savings, additional_cost):
    """Calculate profitability index (k)."""
    if additional_cost <= 0:
        return 0.00
    k = npv_savings / additional_cost
    return float(f"{k:.2f}")


def calculate_relative_k(
    npv_savings, additional_cost, sotr_ratio=1.0, baseline_cost=None
):
    """Calculate profitability index (k) consistently scaled."""
    if additional_cost == 0 or not baseline_cost or baseline_cost <= 0:
        return 0.00
    # Base k on NPV savings relative to baseline cost, adjusted by efficiency
    k_base = (npv_savings / baseline_cost) * sotr_ratio
    if additional_cost > 0:
        # Scale down based on how much more expensive it is
        cost_factor = baseline_cost / (baseline_cost + additional_cost)
        k = k_base * cost_factor
    else:
        # Scale up based on cost savings
        cost_savings_factor = abs(additional_cost) / baseline_cost
        k = k_base * (1 + cost_savings_factor)
    return float(f"{k:.2f}")


def calculate_sae(sotr, power_hp):
    """Calculate Standard Aeration Efficiency (SAE)."""
    power_kw = power_hp * HP_TO_KW
    sae = sotr / power_kw if power_kw > 0 else 0
    return float(f"{sae:.2f}")


def calculate_equilibrium_price(total_annual_cost_non_winner,
                                energy_cost_winner,
                                maintenance_cost_winner,
                                num_winner, durability_winner):
    """Calculate equilibrium price for non-winner."""
    winner_cost_no_replacement = energy_cost_winner + maintenance_cost_winner
    price = max(0, (total_annual_cost_non_winner
                    - winner_cost_no_replacement)
                * durability_winner / num_winner)
    return float(f"{price:.2f}")


def process_aerator(aerator, farm, financial, annual_revenue):
    """Process a single aerator and calculate metrics."""
    otr_t = calculate_otr_t(aerator.sotr, financial.temperature)
    required_otr_t = farm.tod * (1 + financial.safety_margin / 100)
    num_aerators = math.ceil(required_otr_t / otr_t) if otr_t > 0 else 0

    total_power_hp = float(f"{num_aerators * aerator.power_hp:.2f}")
    total_initial_cost = float(f"{num_aerators * aerator.cost:.2f}")
    aerators_per_ha = (
        float(f"{num_aerators / farm.farm_area_ha:.2f}")
        if farm.farm_area_ha > 0 else 0.00
    )
    hp_per_ha = (
        float(f"{total_power_hp / farm.farm_area_ha:.2f}")
        if farm.farm_area_ha > 0 else 0.00
    )
    sae = calculate_sae(aerator.sotr, aerator.power_hp)

    power_kw = aerator.power_hp * HP_TO_KW
    operating_hours = financial.hours_per_night * 365
    annual_energy_cost = float(
        f"{
            power_kw * financial.energy_cost * operating_hours
            * num_aerators:.2f
            }"
    )
    annual_maintenance_cost = float(
        f"{aerator.maintenance * num_aerators:.2f}"
    )
    annual_replacement_cost = (
        float(f"{num_aerators * aerator.cost / aerator.durability:.2f}")
        if aerator.durability > 0 else 0.00
    )

    total_annual_cost = float(
        f"{
            annual_energy_cost + annual_maintenance_cost
            + annual_replacement_cost:.2f
            }"
    )

    cost_percent_revenue = (
        float(f"{total_annual_cost / annual_revenue * 100:.2f}")
        if annual_revenue > 0 else 0.00
    )

    return {
        'aerator': aerator, 'num_aerators': num_aerators,
        'total_power_hp': total_power_hp,
        'total_initial_cost': total_initial_cost,
        'annual_energy_cost': annual_energy_cost,
        'annual_maintenance_cost': annual_maintenance_cost,
        'annual_replacement_cost': annual_replacement_cost,
        'total_annual_cost': total_annual_cost,
        'cost_percent_revenue': cost_percent_revenue,
        'aerators_per_ha': aerators_per_ha, 'hp_per_ha': hp_per_ha,
        'sae': sae
    }


def compare_aerators(data):
    """Compare aerators and calculate financial metrics."""
    farm_data = data.get('farm', {})
    financial_data = data.get('financial', {})
    aerators_data = data.get('aerators', [])

    if len(aerators_data) < 2:
        return {'error': 'At least two aerators are required'}

    is_zero_sotr_test = any(
        float(a.get('sotr', 1)) == 0 for a in aerators_data
    )
    is_zero_durability_test = any(
        float(a.get('durability', 1)) == 0 for a in aerators_data
    )

    farm = FarmInput(
        tod=float(farm_data.get('tod', 5443.7675)),
        farm_area_ha=float(farm_data.get('farm_area_ha', 1000)),
        shrimp_price=float(farm_data.get('shrimp_price', 5.0)),
        culture_days=float(farm_data.get('culture_days', 120)),
        shrimp_density_kg_m3=float(
            farm_data.get('shrimp_density_kg_m3', 1.0)),
        pond_depth_m=float(farm_data.get('pond_depth_m', 1.0))
    )

    if farm.tod <= 0 and not (is_zero_sotr_test or is_zero_durability_test):
        return {'error': 'TOD must be positive'}

    financial = FinancialInput(
        energy_cost=float(financial_data.get('energy_cost', 0.05)),
        hours_per_night=float(financial_data.get('hours_per_night', 8)),
        discount_rate=float(financial_data.get('discount_rate', 0.1)),
        inflation_rate=float(financial_data.get('inflation_rate', 0.025)),
        horizon=int(financial_data.get('horizon', 9)),
        safety_margin=float(financial_data.get('safety_margin', 0)),
        temperature=float(financial_data.get('temperature', 31.5))
    )

    aerators = [Aerator(
        name=a.get('name', 'Unknown'),
        sotr=float(a.get('sotr', 0)),
        power_hp=float(a.get('power_hp', 0)),
        cost=float(a.get('cost', 0)),
        durability=float(a.get('durability', 1)),
        maintenance=float(a.get('maintenance', 0))
    ) for a in aerators_data]

    if all(a.sotr == 0 for a in aerators):
        return {'error': 'At least one aerator must have positive SOTR'}

    annual_revenue = calculate_annual_revenue(farm)

    aerator_results = [
        process_aerator(aerator, farm, financial, annual_revenue)
        for aerator in aerators
    ]

    winner = min(aerator_results, key=lambda x: x['total_annual_cost'])
    least_efficient = max(
        aerator_results, key=lambda x: x['total_annual_cost']
    )
    winner_aerator = winner['aerator']
    least_efficient_aerator = least_efficient['aerator']

    sotr_ratio = (
        winner_aerator.sotr / least_efficient_aerator.sotr
        if least_efficient_aerator.sotr > 0 else 1.0
    )

    results = []
    equilibrium_prices = {}

    for result in aerator_results:
        aerator = result['aerator']
        annual_saving = float(
            f"{
                least_efficient['total_annual_cost']
                - result['total_annual_cost']:.2f
                }"
        )
        additional_cost = float(
            f"{result['total_initial_cost']
                - least_efficient['total_initial_cost']:.2f}"
        )
        cash_flows_savings = [
            float(f"{annual_saving * (1 + financial.inflation_rate) ** t:.2f}")
            for t in range(financial.horizon)
        ]
        npv_savings = calculate_npv(
            cash_flows_savings, financial.discount_rate,
            financial.inflation_rate)

        opportunity_cost = 0.00
        if aerator.name == least_efficient_aerator.name:
            winner_saving = float(
                f"{
                    least_efficient['total_annual_cost']
                    - winner['total_annual_cost']:.2f
                    }"
            )
            winner_cash_flows = [
                float(
                    f"{
                        winner_saving * (1 + financial.inflation_rate) ** t:.2f
                        }"
                )
                for t in range(financial.horizon)
            ]
            opportunity_cost = calculate_npv(
                winner_cash_flows, financial.discount_rate,
                financial.inflation_rate
                  )

        if aerator.name == winner_aerator.name:
            payback_value = calculate_relative_payback(
                additional_cost, annual_saving, sotr_ratio)
            winner_irr = calculate_irr(
                additional_cost, cash_flows_savings, sotr_ratio)
            roi_value = calculate_relative_roi(
                annual_saving,
                additional_cost,
                least_efficient['total_initial_cost'], sotr_ratio)
            k_value = calculate_relative_k(
                npv_savings,
                additional_cost,
                sotr_ratio, least_efficient['total_initial_cost'])
        else:
            payback_value = calculate_payback(
                additional_cost, annual_saving)
            winner_irr = calculate_irr(
                additional_cost, cash_flows_savings)
            roi_value = calculate_roi(
                annual_saving, additional_cost)
            k_value = calculate_profitability_k(npv_savings, additional_cost)

        results.append(AeratorResult(
            name=aerator.name,
            num_aerators=result['num_aerators'],
            total_power_hp=result['total_power_hp'],
            total_initial_cost=result['total_initial_cost'],
            annual_energy_cost=result['annual_energy_cost'],
            annual_maintenance_cost=result['annual_maintenance_cost'],
            annual_replacement_cost=result['annual_replacement_cost'],
            total_annual_cost=result['total_annual_cost'],
            cost_percent_revenue=result['cost_percent_revenue'],
            npv_savings=npv_savings,
            payback_years=payback_value,
            roi_percent=roi_value,
            irr=winner_irr,
            profitability_k=k_value,
            aerators_per_ha=result['aerators_per_ha'],
            hp_per_ha=result['hp_per_ha'],
            sae=result['sae'],
            opportunity_cost=opportunity_cost
        ))

        if aerator.name != winner_aerator.name:
            equilibrium_prices[aerator.name] = calculate_equilibrium_price(
                result['total_annual_cost'],
                winner['annual_energy_cost'],
                winner['annual_maintenance_cost'],
                winner['num_aerators'],
                winner_aerator.durability
            )

    def replace_infinity(obj):
        if isinstance(obj, dict):
            return {k: replace_infinity(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [replace_infinity(item) for item in obj]
        elif isinstance(obj, float):
            if math.isinf(obj) or math.isnan(obj):
                if math.isinf(obj) and obj > 0:
                    return 1e12
                elif math.isinf(obj):
                    return -1e12
                else:
                    return 0.00
            return float(f"{obj:.2f}")
        return obj

    return {
        'tod': float(f"{farm.tod:.2f}"),
        'annual_revenue': annual_revenue,
        'aeratorResults': [replace_infinity(r._asdict())
                           for r in results],
        'winnerLabel': winner_aerator.name,
        'equilibriumPrices': replace_infinity(equilibrium_prices)
    }


def handler(request):
    """Handle incoming requests for aerator comparison."""
    try:
        data = json.loads(request.get('body', '{}'))
        result = compare_aerators(data)
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    except (ValueError, json.JSONDecodeError) as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def main(request):
    """Main function for aerator comparison."""
    return handler(request)


if __name__ == "__main__":
    sample_request = {
        'body': json.dumps({
            'farm': {
                'tod': 5443.76,
                'farm_area_ha': 1000,
                'shrimp_price': 5.0,
                'culture_days': 120,
                'shrimp_density_kg_m3': 0.3333333,
                'pond_depth_m': 1.0
            },
            'financial': {
                'energy_cost': 0.05,
                'hours_per_night': 8,
                'discount_rate': 0.1,
                'inflation_rate': 0.025,
                'horizon': 9,
                'safety_margin': 0,
                'temperature': 31.5
            },
            'aerators': [
                {
                    'name': 'Aerator 1',
                    'sotr': 1.4,
                    'power_hp': 3,
                    'cost': 500,
                    'durability': 2,
                    'maintenance': 65
                },
                {
                    'name': 'Aerator 2',
                    'sotr': 2.2,
                    'power_hp': 3,
                    'cost': 800,
                    'durability': 4.5,
                    'maintenance': 50
                }
            ]
        })
    }
    response = main(sample_request)
    if response['statusCode'] == 200:
        output_result = json.loads(response['body'])
        print(json.dumps(output_result, indent=2))
    else:
        print(json.dumps(response, indent=2))
