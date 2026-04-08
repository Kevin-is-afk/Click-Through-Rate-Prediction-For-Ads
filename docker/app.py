from flask import Flask, jsonify, request
import pandas as pd

app = Flask(__name__)

@app.route('/data')
def get_data():
    df = pd.read_csv('rf_predictions.csv')
    return jsonify(df.to_dict(orient='records'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
