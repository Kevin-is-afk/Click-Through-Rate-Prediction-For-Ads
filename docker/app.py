from flask import Flask, jsonify
import pandas as pd

app = Flask(__name__)

@app.route('/data')
def get_data():
    df = pd.read_csv('data.csv')  # your repo file
    return df.to_json(orient='records')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)