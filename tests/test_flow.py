import pytest
import brownie

from brownie import GiantsPlanet, TokenSale, Airdrops, Token, reverts

# Constants
TOKEN_BUYERS = 10
ITEM_COST = 100E18
PERCENTAGE_BUY = 0.9
BLOCK_END = 1000

# Fixtures

@pytest.fixture(scope='module')
def deployer():
    """Fixture to represent the account deploying the contracts."""
    return brownie.accounts[0]

@pytest.fixture(scope='module')
def users():
    """Fixture to represent the users who will interact with the contracts."""
    return [brownie.accounts.add() for acc in range(TOKEN_BUYERS)]

@pytest.fixture(scope='module')
def usdt(deployer):
    """Fixture to represent the USDT token contract."""
    return Token.deploy({'from': deployer})

@pytest.fixture(scope='module')
def token_sale(deployer, usdt):
    """Fixture to represent the token sale contract."""
    return TokenSale.deploy(usdt.address, ITEM_COST, 0, BLOCK_END, {'from': deployer})

@pytest.fixture(scope='module')
def giants_planet(deployer, token_sale):
    """Fixture to represent the GiantsPlanet contract."""
    return GiantsPlanet.deploy("GiantsPlanet", "GP", "test/", {'from': deployer})

@pytest.fixture(scope='module')
def airdrops(deployer, giants_planet):
    """Fixture to represent the Airdrops contract."""
    return Airdrops.deploy(giants_planet.address, 1, {'from': deployer})

# Tests

def test_token_sale(deployer, users, usdt, token_sale):
    """Test the functionality of the token sale contract."""
    for user in users:
        usdt.mint(user, ITEM_COST * 100E18, {'from': deployer})
    
    for user in users:
        with reverts("Amount 0"):
            usdt.approve(token_sale.address, ITEM_COST, {'from': user})
            token_sale.purchase(0, 1, {'from': user})

        usdt.approve(token_sale.address, ITEM_COST, {'from': user})
        token_sale.purchase(1, ITEM_COST, {'from': user})

        usdt.approve(token_sale.address, ITEM_COST * 10, {'from': user})
        token_sale.purchase(10, ITEM_COST * 10, {'from': user})

        with reverts("Limit reached"):
            usdt.approve(token_sale.address, ITEM_COST * 100, {'from': user})
            token_sale.purchase(100, ITEM_COST * 100, {'from': user})

        with reverts():
            usdt.approve(token_sale.address, ITEM_COST * 2, {'from': user})
            token_sale.purchase(1, ITEM_COST * 2, {'from': user})
    
    with reverts("Sale not ended"):
        token_sale.withdrawTokens(usdt.address, usdt.balanceOf(token_sale.address), {'from': deployer})

    brownie.chain.mine(BLOCK_END - brownie.chain.height)
    with reverts("Sale not active"):
        token_sale.purchase(1, ITEM_COST * 2, {'from': users[0]})
    token_sale.withdrawTokens(usdt.address, usdt.balanceOf(token_sale.address), {'from': deployer})


def test_giants_planet(deployer, airdrops, giants_planet):
    """Test the functionality of the GiantsPlanet contract."""
    giants_planet.setOperator(airdrops.address, True, {'from': deployer})
    giants_planet.setOperator(deployer.address, True, {'from': deployer})
    giants_planet.newSeries("Test", {'from': deployer})
    assert giants_planet.seriesNames(1) == "Test"
    giants_planet.mint(deployer.address, 1, 1, b'')
    assert giants_planet.balanceOf(deployer.address, 1) == 1


def test_airdrops(deployer, users, usdt, airdrops):
    """Test the functionality of the Airdrops contract."""
    split = int(len(users) * PERCENTAGE_BUY)

    for user in users[:split]:
        airdrops.airdrop(user.address, 1, b'', {'from': deployer})
    
    for user in users[split:]:
        usdt.approve(airdrops.address, ITEM_COST * 11)
        airdrops.refund(usdt.address, [user], [ITEM_COST * 11], {'from': deployer})