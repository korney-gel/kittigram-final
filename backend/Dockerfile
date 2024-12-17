FROM python:3.10 AS build
WORKDIR /code
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

FROM python:3.10-alpine
ENV PYTHONUNBUFFERED=1
COPY --from=build /code /code
EXPOSE 8000
CMD ["python","manage.py","runserver","0.0.0.0:8000"]