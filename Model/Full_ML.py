import os
import io
import pickle
import pandas as pd
from google.cloud import vision_v1
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
from sklearn.metrics.pairwise import cosine_similarity
from pythainlp import word_tokenize
import re

# โหลดข้อมูลจากไฟล์ CSV
try:
    data = pd.read_csv('Book2.csv', encoding='utf-8', on_bad_lines='warn')
except UnicodeDecodeError:
    data = pd.read_csv('Book2.csv', encoding='ISO-8859-1', on_bad_lines='warn')

# ตั้งค่าคีย์ API ของ Google Cloud
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'project-service.json'
client = vision_v1.ImageAnnotatorClient()

# ตั้งค่าพาธของไฟล์รูปภาพ
file_name = 'k1.jpg'
image_folder = 'C:/Users/User/google_vision_ai_demo'
image_path = os.path.join(image_folder, file_name)

# อ่านข้อมูลรูปภาพ
with io.open(image_path, 'rb') as image_file:
    content = image_file.read()

image = vision_v1.types.Image(content=content)

# สร้าง dataframe สำหรับการเทรนโมเดล
df = pd.DataFrame(data, columns=['description', 'type', 'use'])
df['description'] = df['description'].apply(lambda x: ' '.join(word_tokenize(x, engine='newmm')))

# ทำการตรวจจับข้อความในรูปภาพ
response = client.text_detection(image=image)
texts = response.text_annotations

# ฟังก์ชันสำหรับกรองเฉพาะตัวอักษรและตัวเลข
def filter_alnum(text):
    return ''.join(filter(str.isalnum, text))

# ฟังก์ชันสำหรับกรองเฉพาะตัวอักษรและตัวเลข รวมถึงภาษาไทย
def filter_alnum_thai(text):
    return ''.join(filter(lambda x: x.isalnum() or '\u0E00' <= x <= '\u0E7F', text))

# ฟังก์ชันสำหรับประมวลผลข้อความจาก OCR
def process_text(text):
    return ' '.join(word_tokenize(text, engine='newmm'))

# ฟังก์ชันตรวจสอบภาษาของข้อความ
def is_thai(text):
    return any('\u0E00' <= char <= '\u0E7F' for char in text)

# ฟังก์ชันสำหรับกรองและประมวลผลข้อความ
full_text = ''.join([text.description.replace('\n', '').replace(' ', '') for text in texts])
filtered_text = filter_alnum_thai(full_text)

print(filtered_text)

# กรองและรวมข้อความจาก OCR
ocr_texts = [filter_alnum(text.description) for text in texts if filter_alnum(text.description)]

# แปลงข้อความเป็น vectors โดยใช้ TfidfVectorizer
vectorizer = TfidfVectorizer()
vectors = vectorizer.fit_transform(data['name'].dropna().unique())
ocr_vector = vectorizer.transform([' '.join(ocr_texts)])

# คำนวณค่า cosine similarity ระหว่าง vectors
cosine_similarities = cosine_similarity(ocr_vector, vectors).flatten()
highest_similarity_index = cosine_similarities.argmax()
highest_similarity_value = cosine_similarities[highest_similarity_index]

# กำหนดค่า similarity ที่เหมาะสม
similarity_threshold = 0.5

if highest_similarity_value >= similarity_threshold:
    best_match = data['name'].dropna().unique()[highest_similarity_index]
    matches = data[data['name'].str.contains(best_match, case=False, na=False)]
    if not matches.empty:
        print("Matched with name in dataset:")
        print(matches.iloc[0])  # แสดงเพียงแถวแรกที่พบ
    else:
        print('not match')
else:
    # ตรวจสอบว่าข้อความเป็นภาษาไทยหรือไม่
    if not is_thai(filtered_text):
        print("No data.")

    else:
        full_text = re.sub(r',+', '', full_text)
        # processed_text = process_text(filtered_text)

        # ตรวจสอบความเหมือนของข้อความ OCR กับ df['description'] โดยใช้ cosine similarity
        vectorizer = TfidfVectorizer()
        vectors = vectorizer.fit_transform(df['description'].dropna().unique())
        ocr_vector = vectorizer.transform([full_text])
        cosine_similarities = cosine_similarity(ocr_vector, vectors).flatten()
        highest_similarity_index = cosine_similarities.argmax()
        highest_similarity_value = cosine_similarities[highest_similarity_index]

        similarity_threshold = 0.2  # กำหนดค่า threshold ความเหมือนที่เหมาะสม

        print(ocr_vector)



        if highest_similarity_value >= similarity_threshold:
            best_match = df['description'].dropna().unique()[highest_similarity_index]
            matches = df[df['description'].str.contains(best_match, case=False, na=False)]
        else:
            print("No similar description found.")
            exit()


        # แบ่งข้อมูลเป็น train และ test set
        X_train, X_test, y_train, y_test = train_test_split(df['description'], df['type'], test_size=0.2, random_state=42)

        # สร้าง Pipeline สำหรับการแปลงข้อความและเทรนโมเดล
        model = Pipeline([
            ('vectorizer', CountVectorizer()),
            ('classifier', MultinomialNB())
        ])

        # เทรนโมเดล
        model.fit(X_train, y_train)

        # ประเมินผลโมเดล
        y_pred = model.predict(X_test)

        # ใช้โมเดลที่เทรนในการทำนายประเภทของข้อความที่ได้รับจาก OCR
        predicted_type = model.predict([processed_text])[0]

        # บันทึกโมเดลลงในไฟล์
        with open('text_classifier.pkl', 'wb') as file:
            pickle.dump(model, file)

        # โหลดโมเดลจากไฟล์ (หากต้องการ)
        with open('text_classifier.pkl', 'rb') as file:
            loaded_model = pickle.load(file)

        # ใช้โมเดลที่โหลดในการทำนาย
        predicted_type_loaded = loaded_model.predict([full_text])[0]
        print(f"Predicted type using loaded model: {predicted_type_loaded}")

        # จับคู่และแสดงข้อมูลที่เกี่ยวข้องจาก CSV สำหรับ type ที่ทำนายได้
        matching_rows_loaded = df[df['type'] == predicted_type_loaded]

        if not matching_rows_loaded.empty:
            row = matching_rows_loaded.iloc[0]
            print(f"Type: {row['type']}, Use: {row['use']}")
        else:
            print("No matching data found in CSV.")
            
            
            
