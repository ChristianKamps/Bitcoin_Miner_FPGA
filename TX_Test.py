import time     # Time Library - Used to Timeout
import serial   # Serial Library - Used for Serial TX/RX
import binascii # Binary-ASCII Library - Used for Hex-to-Byte conversion for Serial Library

# Communication Port Setup:
ser = serial.Serial()
ser.port = 'COM3'                   # Communication Port = COM3 for UART USB
ser.baudrate = 9600                 # Baud Rate = 9600
ser.bytesize = serial.EIGHTBITS     # Data Bits = 8 
ser.parity = serial.PARITY_NONE     # Parity Bit = None
ser.stopbits = serial.STOPBITS_ONE  # Stop Bits = 1
ser.timeout = None                  # Timeout = None
ser.xonxoff = False                 # Disable Software Flow Control
ser.rtscts = False                  # Disable Hardware (RTS/CTS) Flow Control
ser.dsrdtr = False                  # Disable Hardware (DSR/DTR) Clow Control
ser.write_timeout = False           # Disable Write Timeout
ser.inter_byte_timeout = None       # Disable Inter-Character Timeout
ser.exclusive = None                # Disable Exclusive Access Mode (POSIX Only)

# Transmission Data Setup:
Random_Hex = '21'  # ! only need this to be sent once at the start
Random_Byte = bytes.fromhex(Random_Hex) 
Training_Sequence_Hex = '61626364'  # abcd
Training_Sequence_Bytes = bytes.fromhex(Training_Sequence_Hex) 
print("Training Sequence: ", Training_Sequence_Bytes)
#Message_Hex = '30313233343536373839' # 0123456789
Message_Hex='0080e421911664ee03a9599fb71ea9e68e4841313c4edff600980400000000000000000019610a6dfe3741e7c39df94af992f1df8101b423c73d88bbe923a96a220c9aa01acd326273370a17804c52eb'
Message_Bytes = bytes.fromhex(Message_Hex)
print("Message: ", Message_Bytes)
TX_Data = Training_Sequence_Bytes + Message_Bytes
print("TX_Data: ", TX_Data)


# Open the UART-USB Serial Port located at port: COM3
try:
    ser.open()
except Exception as e1:
    print("Serial port: ",ser.port," failed to open. ERROR: ", str(e1))
    exit()

# If the port is open
if ser.isOpen():
    print("Opened Port: ",ser.port, " . Attempting to read data.")
    # Flush the input and output buffers
    try:
        ser.flushInput()    # Flush the input buffer
        ser.flushOutput()   # Flush the output buffer
    except Exception as e2:
        print("Serial port: ",ser.port," failed to flesh. ERROR: ", str(e2))    
    # Send Data:
    ser.write(Random_Byte)
    ser.write(TX_Data)    
    # Continuously read the data from the Communication Port and print it to the console
    record = []
    while True:        
        RX_Data = ser.read()
        record.append(RX_Data.hex()) # Append the received data to list 'record' in hex format
        print(RX_Data)
        if (len(record) == 10):
            print('[%s]' % ', '.join(map(str, record)))
            record.clear()
else:
    print("Serial port: ",ser.port," is closed.")