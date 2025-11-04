import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv
import os

load_dotenv()  # lê o .env

def get_connection2():
    try:
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME'),
            port=int(os.getenv('DB_PORT', 3306))
        )
        return connection
    except Error as e:
        print(f"Erro ao conectar ao MySQL: {e}")
        return None
        

def get_connection():
    return mysql.connector.connect(
        host="RAILWAY_HOST",
        user="RAILWAY_USER",
        password="RAILWAY_PASSWORD",
        database="RAILWAY_DB"
    )