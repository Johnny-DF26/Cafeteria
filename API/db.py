import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv
import os

load_dotenv()  # lê o .env

def get_connection2():
    try:
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST_LOCAL'),
            user=os.getenv('DB_USER_LOCAL'),
            password=os.getenv('DB_PASSWORD_LOCAL'),
            database=os.getenv('DB_NAME_LOCAL'),
            port=int(os.getenv('DB_PORT_LOCAL', 3306))
        )
        return connection
    except Error as e:
        print(f"Erro ao conectar ao MySQL: {e}")
        return None
    


def get_connection():
    try:
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME'),
            port=int(os.getenv('DB_PORT', 3306))
        )
        if connection.is_connected():
            print("Conectado ao MySQL!")
        return connection
    except Error as e:
        print("Erro detalhado:", e)
        return None

