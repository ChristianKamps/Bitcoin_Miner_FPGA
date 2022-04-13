# This program uses the API from blockchain.com (https://www.blockchain.com/api/blockchain_api) to get:
#   - Latest Block Height                       : latest_block_height   : 6-decimal
#   - Latest Block Hash                         : latest_block_hash     : 64-hex
#   - 10 Unconfirmed transaction hashes (TXID)  : tx[i]                 : 64-hex
#   - Timestamp                                 : Unix Epoch Time       :  8-hex

# nBits is hard coded into the FGPA as it doesnt change often   

import json             # JSON library
import urllib.request   # URL request library
import time             # Time

# Get the previous block hash and block height from blockchain.info:
latest_block_file = urllib.request.urlopen("https://blockchain.info/latestblock").read() # Open the URL which return a Python byte class to be read
latest_block_json = json.loads(latest_block_file) # Convert latest_block_file into a Python dictionary
latest_block_height = hex(latest_block_json['height']) # Store the latest block's block height (6-digit number(At most 5-hex(20-bit)))
print("Latest Block Height: ",latest_block_height)
latest_block_hash = latest_block_json['hash'] # Store the latest block's hash in hex (64-hex (256-bit))
print("Latest Block Hash: ",latest_block_hash)

# Get 10 unconfirmed transaction hashes (64-hex (256-bit)) from blockchain.info:
tx_data = urllib.request.urlopen("https://blockchain.info/unconfirmed-transactions?format=json").read() # Open the URL which return a Python file to be read
tx_output = json.loads(tx_data) # Convert the tx_data into a Python dictionary
tx={} # Array for 10 unfconfirmed transactions
for i in range(0, 10):
    tx[i] = tx_output['txs'][i]['hash'] # Grab the first 10 transaction hashes ('hash') under 'txs' in hex (64-hex (256-bit))
    print("TXID(",i,"): ",tx[i])

# Unix Epoch Time
print("Time: ", hex(int(time.time())))