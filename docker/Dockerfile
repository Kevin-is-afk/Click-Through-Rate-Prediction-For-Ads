FROM python:3.10

WORKDIR /app


COPY docker/app.py .
COPY docker/rf_predictions.csv .
COPY data/ data/
COPY outputs/ outputs/
COPY scripts/ scripts/
copy Dataset/ Dataset/

RUN pip install flask pandas

EXPOSE 5000

CMD ["python", "app.py"]
