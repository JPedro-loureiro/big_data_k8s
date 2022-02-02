FROM python:3.8

RUN mkdir -p /data_source_generator/app/

WORKDIR /data_source_generator/app/

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY main.py .

CMD ["python3", "main.py"]