"""aerator_comparer.py
This module provides functionality to compare different aerators based on their
specifications and financial metrics.
It includes functions to calculate NPV, IRR, payback period, ROI, and
profitability index.
It also handles the processing of incoming requests and returns the comparison
results in a structured format.
"""
import json
import math
from collections import namedtuple

# Data structures using namedtuple
Aerator = namedtuple(
    'Aerator',
    [
        'name',
        'sotr',
        'power_hp',
        'cost',
        'durability',
        'maintenance'
    ]
)
FinancialInput = namedtuple(
    'FinancialInput',
    [
        'energy_cost',
        'operating_hours',
        'discount_rate',
        'inflation_rate',
        'horizon',
        'safety_margin'
    ]
)
AeratorResult = namedtuple(
    'AeratorResult',
    [
        'name',
        'num_aerators',
        'total_power_hp',
        'total_initial_cost',
        'annual_energy_cost',
        'annual_maintenance_cost',
        'npv_cost',
        'aerators_per_ha',
        'hp_per_ha',
        'sae',
        'payback_years',
        'roi_percent',
        'irr',
        'profitability_k'
    ]
)

# Constants
HP_TO_KW = 0.746


# Financial calculation functions
def calculate_npv(cash_flows, discount_rate, inflation_rate):
    """
    Calculate the Net Present Value (NPV) of a series of cash flows.

    :param cash_flows: List of cash flows
    :param discount_rate: Discount rate as a decimal
    :param inflation_rate: Inflation rate as a decimal
    :return: NPV value
    """
    real_discount_rate = (
        (1 + discount_rate) / (1 + inflation_rate) - 1
        if inflation_rate != discount_rate
        else 0
    )
    return sum(
        cf / (1 + real_discount_rate) ** (i + 1)
        for i, cf in enumerate(cash_flows)
    ) if real_discount_rate > -1 else 0


def newton_raphson(func, func_prime, x0, tol=1e-6, maxiter=100):
    """
    Newton-Raphson method for finding roots of a function.

    :param func: Function for which to find the root
    :param func_prime: Derivative of the function
    :param x0: Initial guess
    :param tol: Tolerance for convergence
    :param maxiter: Maximum number of iterations
    :return: Approximate root
    """
    x = x0
    for _ in range(maxiter):
        fx = func(x)
        fpx = func_prime(x)
        if abs(fpx) < 1e-10:
            return 0  # Avoid division by zero
        delta_x = fx / fpx
        x -= delta_x
        if abs(delta_x) < tol:
            return x
    return x


def calculate_irr(initial_investment, cash_flows):
    """
    Calculate the Internal Rate of Return (IRR) for a series of cash flows.

    :param initial_investment: Initial investment amount
    :param cash_flows: List of cash flows
    :return: IRR value as a percentage
    """
    def npv_func(rate):
        """
        Calculate the Net Present Value (NPV) for a given discount rate.

        :param rate: Discount rate as a decimal
        :return: NPV value
        """
        if rate <= -1:
            return float('inf')
        return -initial_investment + sum(
            cf / (1 + rate) ** (i + 1) for i,
            cf in enumerate(cash_flows)
        )

    def npv_prime(rate):
        """
        Calculate the derivative of the NPV function.

        :param rate: Discount rate as a decimal
        :return: Derivative of NPV
        """
        if rate <= -1:
            return 0
        return sum(
            -(i + 1) * cf / (1 + rate) ** (i + 2)
            for i, cf in enumerate(cash_flows)
        )

    try:
        irr = newton_raphson(npv_func, npv_prime, 0.1)
        return irr * 100 if -0.99 < irr < 5 else -100
    except (ZeroDivisionError, ValueError, OverflowError):
        return -100


def calculate_payback(initial_investment, cash_flows):
    """
    Calculate the payback period for a series of cash flows.

    :param initial_investment: Initial investment amount
    :param cash_flows: List of cash flows
    :return: Payback period in years
    """
    cumulative = -initial_investment
    for i, cf in enumerate(cash_flows):
        cumulative += cf
        if cumulative >= 0:
            return (i + 1) - (cumulative / cf) if cf != 0 else i + 1
    return float('inf')


def calculate_roi(initial_investment, cash_flows):
    """
    Calculate the Return on Investment (ROI) for a series of cash flows.

    :param initial_investment: Initial investment amount
    :param cash_flows: List of cash flows
    :return: ROI value as a percentage
    """
    total_savings = sum(cash_flows)
    return (
        ((total_savings - initial_investment) / initial_investment) * 100
        if initial_investment > 0 else 0
    )


def calculate_profitability_k(npv, initial_investment):
    """
    Calculate the profitability index (PI) for a series of cash flows.

    :param npv: Net Present Value (NPV)
    :param initial_investment: Initial investment amount
    :return: Profitability index (PI) value
    """
    return npv / initial_investment if initial_investment > 0 else 0


def calculate_sae(sotr, power_hp):
    """
    Calculate the Specific Aeration Efficiency (SAE) for an aerator.

    :param sotr: Standard Oxygen Transfer Rate (SOTR)
    :param power_hp: Power in horsepower (HP)
    :return: SAE value
    """
    power_kw = power_hp * HP_TO_KW
    return sotr / power_kw if power_kw > 0 else 0


def calculate_equilibrium_price(
        baseline_cost,
        winner_cost_no_price,
        winner_units):
    """
    Calculate the equilibrium price for an aerator based on baseline costs and
    winner costs.

    :param baseline_cost: Baseline cost of the aerator
    :param winner_cost_no_price: Cost of the winning aerator without price
    :param winner_units: Number of units of the winning aerator
    :return: Equilibrium price
    """
    return max(
        0, (baseline_cost - winner_cost_no_price) / winner_units
    ) if winner_units > 0 else 0


def process_aerator(aerator, tod, farm_area_ha, financial, baseline_costs):
    """
    Process a single aerator and calculate its financial metrics.

    :param aerator: Aerator object
    :param tod: Total Oxygen Demand (TOD)
    :param farm_area_ha: Farm area in hectares
    :param financial: FinancialInput object
    :param baseline_costs: Dictionary of baseline costs for comparison
    :return: AeratorResult object with calculated metrics
    """
    required_sotr = tod * (1 + financial.safety_margin / 100)
    num_aerators = (
        math.ceil(required_sotr / aerator.sotr) if aerator.sotr > 0 else 0
    )

    # Technical metrics
    total_power_hp = num_aerators * aerator.power_hp
    total_initial_cost = num_aerators * aerator.cost
    aerators_per_ha = (
        num_aerators / farm_area_ha if farm_area_ha > 0 else 0
    )
    hp_per_ha = (
        total_power_hp / farm_area_ha if farm_area_ha > 0 else 0
    )
    sae = calculate_sae(
        aerator.sotr,
        aerator.power_hp
    )

    # Annual costs
    power_kw = aerator.power_hp * HP_TO_KW
    annual_energy_cost = (
        power_kw * financial.energy_cost * financial.operating_hours
        * num_aerators
    )
    annual_maintenance_cost = aerator.maintenance * num_aerators
    annualized_replacement = (
        (num_aerators * aerator.cost) / aerator.durability
        if aerator.durability > 0 else 0
    )
    total_annual_cost = (
        annual_energy_cost + annual_maintenance_cost + annualized_replacement
    )

    # Cash flows for financial metrics
    def calculate_year_cost(year):
        return (
            annual_energy_cost + annual_maintenance_cost +
            (
                total_initial_cost if aerator.durability > 0 and
                year % math.ceil(aerator.durability) == 0 else 0
            )
        )
    cash_flows = [
        -calculate_year_cost(year) * (1 + financial.inflation_rate) ** year
        for year in range(1, financial.horizon + 1)
    ]

    # Financial metrics
    npv_cost = (
        calculate_npv(
            cash_flows,
            financial.discount_rate,
            financial.inflation_rate
        ) - total_initial_cost
    )
    cash_flows_savings = [
        baseline_costs.get(
            aerator.name,
            total_annual_cost
        ) - total_annual_cost
        for _ in range(financial.horizon)
    ]
    irr = calculate_irr(
        total_initial_cost,
        cash_flows_savings
    )
    payback = calculate_payback(
        total_initial_cost,
        cash_flows_savings
    )
    roi = calculate_roi(
        total_initial_cost,
        cash_flows_savings
    )
    profitability_k = calculate_profitability_k(
        sum(cash_flows_savings) / (1 + financial.discount_rate),
        total_initial_cost
    )

    return AeratorResult(
        name=aerator.name,
        num_aerators=num_aerators,
        total_power_hp=total_power_hp,
        total_initial_cost=total_initial_cost,
        annual_energy_cost=annual_energy_cost,
        annual_maintenance_cost=annual_maintenance_cost,
        npv_cost=npv_cost,
        aerators_per_ha=aerators_per_ha,
        hp_per_ha=hp_per_ha,
        sae=sae,
        payback_years=payback,
        roi_percent=roi,
        irr=irr,
        profitability_k=profitability_k
    )


def compare_aerators(data):
    """
    Compares multiple aerators based on their specifications and financial
    metrics.
    Returns the results including the winner and equilibrium prices.
    """
    tod = data.get(
        'tod', 0
    )
    farm_area_ha = data.get(
        'farm_area_ha', 1000
    )
    financial_data = data.get(
        'financial', {}
    )
    aerators_data = data.get(
        'aerators', []
    )

    if len(aerators_data) < 2:
        return {
            'error': 'At least two aerators are required'
        }
    if tod <= 0:
        return {
            'error': 'TOD must be positive'
        }

    financial = FinancialInput(
        energy_cost=float(
            financial_data.get(
                'energy_cost', 0.05
            )
        ),
        operating_hours=float(
            financial_data.get(
                'operating_hours', 2920
            )
        ),
        discount_rate=float(
            financial_data.get(
                'discount_rate', 0.1
            )
        ),
        inflation_rate=float(
            financial_data.get(
                'inflation_rate', 0.025
            )
        ),
        horizon=int(
            financial_data.get(
                'horizon', 9
            )
        ),
        safety_margin=float(
            financial_data.get(
                'safety_margin', 0
            )
        )
    )

    aerators = list(map(
        lambda a: Aerator(
            name=a.get(
                'name', 'Unknown'
            ),
            sotr=float(
                a.get(
                    'sotr', 0
                )
            ),
            power_hp=float(
                a.get(
                    'power_hp', 0
                )
            ),
            cost=float(
                a.get(
                    'cost', 0
                )
            ),
            durability=float(
                a.get(
                    'durability', 1
                )
            ),
            maintenance=float(
                a.get(
                    'maintenance', 0
                )
            )
        ),
        aerators_data
    ))

    # Calculate baseline costs dynamically
    baseline_costs = {}
    results = []
    for aerator in aerators:
        result = process_aerator(
            aerator, tod,
            farm_area_ha,
            financial,
            baseline_costs
        )
        baseline_costs[aerator.name] = (
            result.annual_energy_cost + result.annual_maintenance_cost +
            (
                result.total_initial_cost / aerator.durability
                if aerator.durability > 0 else 0
            )
        )
        results.append(result)

    # Determine winner and compute equilibrium prices
    winner = max(
        results,
        key=lambda x: x.npv_cost
    )
    equilibrium_prices = {}
    for result in filter(
            lambda r: r.name != winner.name,
            results
    ):
        winner_cost_no_price = (
            winner.annual_energy_cost + winner.annual_maintenance_cost +
            (
                winner.total_initial_cost / winner.durability
                if winner.durability > 0 else 0
            )
        )
        equilibrium_prices[result.name] = calculate_equilibrium_price(
            baseline_costs[result.name],
            winner_cost_no_price,
            winner.num_aerators
        )

    return {
        'tod': tod,
        'aeratorResults': [r._asdict() for r in results],
        'winnerLabel': winner.name,
        'equilibriumPrices': equilibrium_prices
    }


def handler(request):
    """
    Handles incoming requests for aerator comparison.
    Parses the request body and returns the comparison results.
    """
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
    """
    Main function to run the aerator comparison.
    This function is designed to be called from an AWS Lambda function or
    similar environment.
    """
    return handler(request)


if __name__ == "__main__":
    sample_request = {
        'body': json.dumps({
            'tod': 5443.7675,
            'farm_area_ha': 1000,
            'financial': {
                'energy_cost': 0.05,
                'operating_hours': 2920,
                'discount_rate': 0.1,
                'inflation_rate': 0.025,
                'horizon': 9,
                'safety_margin': 0
            },
            'aerators': [
                {
                    'name': 'Aerator 1', 'sotr': 1.4, 'power_hp': 3,
                    'cost': 500, 'durability': 2, 'maintenance': 65
                },
                {
                    'name': 'Aerator 2', 'sotr': 2.2, 'power_hp': 3.5,
                    'cost': 800, 'durability': 4.5, 'maintenance': 50
                }
            ]
        })
    }
    print(json.dumps(main(sample_request), indent=2))
