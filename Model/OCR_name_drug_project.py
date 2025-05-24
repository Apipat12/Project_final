import os, io
from google.cloud import vision_v1
from draw_vertice import drawVertices
import pandas as pd
import string

try:
    data = pd.read_csv('Book1.csv', encoding='utf-8', on_bad_lines='warn')
except UnicodeDecodeError:
    data = pd.read_csv('Book1.csv', encoding='ISO-8859-1', on_bad_lines='warn')

#print("Columns in the dataset:", data.columns)   

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'project-service.json'
client = vision_v1.ImageAnnotatorClient()

file_name = 'Benadryl.jpg'
image_folder = 'C:/Users/User/google_vision_ai_demo/'
image_path = os.path.join(image_folder, file_name)

with io.open(image_path, 'rb') as image_file:
    content = image_file.read()

image = vision_v1.types.Image(content=content)
response = client.text_detection(image=image)
texts = response.text_annotations


for text in texts:
    string_filtered = ''.join(filter(str.isalnum, text.description))
    if len(string_filtered) > 4:
        # print('Detected text:', string_filtered)
        if 'name' in data.columns:
            matches = data[data['name'].str.contains(string_filtered, case=False, na=False)]
            if not matches.empty:
                print(matches)


