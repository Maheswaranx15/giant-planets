from brownie import accounts, TokenSaleV2

RECEIVER = "0x211ceab4f180D3cD0EAb96e19F98568B4529EaA2"
SWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
DECIMALS = 6
ITEM_VALUE = 100 * 10 ** DECIMALS
START_TIME = 1701133200
END_TIME = 1701925200

deployer = accounts.load('2mr2')

chain = {
    1: {
        "pay_token": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        "weth": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    },
    137: {
        "pay_token": "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
        "weth": "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
    }
}

def deploy(pay_token, weth):
    token_sale = TokenSaleV2.deploy(RECEIVER, SWAP_ROUTER, pay_token, weth, ITEM_VALUE, START_TIME, END_TIME, {'from': deployer})
    token_sale.transferOwnership(RECEIVER, 36000)

def deploy_polygon():
    deploy(chain[137]["pay_token"], chain[137]["weth"])

def deploy_ethereum():
    deploy(chain[1]["pay_token"], chain[1]["weth"])
