import os
import io
import pandas as pd
import re
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from google.cloud import vision_v1
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.models import load_model
from sklearn.model_selection import train_test_split
from tensorflow.keras.utils import to_categorical
from sklearn.preprocessing import LabelEncoder
from typing import Optional
import pickle
from google.cloud import vision_v1
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from pythainlp import word_tokenize

app = FastAPI()

# ตั้งค่าคีย์ API ของ Google Cloud
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'project-service.json'
client = vision_v1.ImageAnnotatorClient()

# โหลดข้อมูลจากไฟล์ CSV
try:
    data = pd.read_csv('Book2.csv', encoding='utf-8', on_bad_lines='warn')
except UnicodeDecodeError:
    data = pd.read_csv('Book2.csv', encoding='ISO-8859-1', on_bad_lines='warn')


# โหลดข้อมูลจากไฟล์ CSV
try:
    data1 = pd.read_csv('medicine_dataset1.csv', encoding='utf-8', on_bad_lines='warn')
except UnicodeDecodeError:
    data1 = pd.read_csv('medicine_dataset1.csv', encoding='ISO-8859-1', on_bad_lines='warn')



# สร้าง dataframe สำหรับการประมวลผลโมเดล
df3 = pd.DataFrame(data1, columns=['name','use0', 'Therapeutic Class', 'sideEffect0'])
df3['use0'] = df3['use0'].apply(lambda x: ','.join(str(x).split()))

# ตัดตัวเลขออกจากคอลัมน์ name
df3['name'] = df3['name'].str.replace(r'\d+', '', regex=True)

# ตัดคำว่า mg ออกจากคอลัมน์ name
df3['name'] = df3['name'].str.replace('mg', '', regex=True)

df3['name'] = df3['name'].str.replace('tablet', '', regex=True)

df3['name'] = df3['name'].str.replace('capsule', '', regex=True)

# ลบช่องว่างซ้ำที่เหลือจากการตัดข้อมูล
df3['name'] = df3['name'].str.strip() 

# โหลดโมเดลที่เทรนแล้ว
with open('text_classifier.pkl', 'rb') as file:
    loaded_model = pickle.load(file)

# สร้าง dataframe สำหรับการเทรนโมเดล
df = pd.DataFrame(data, columns=['description', 'type', 'use'])
df['description'] = df['description'].apply(lambda x: ' '.join(word_tokenize(x, engine='newmm')))

class OCRResponse(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    type: Optional[str] = None
    use: Optional[str] = None
    therapeutic_class: Optional[str] = None
    use0: Optional[str] = None
    side_effect0: Optional[str] = None
    error: Optional[str] = None

@app.post("/predictTH/")
async def predict(file: UploadFile = File(...)):
    # อ่านข้อมูลรูปภาพ
    try:
        content = await file.read()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read file: {e}")

    image = vision_v1.Image(content=content)

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
            result = OCRResponse(
                name=matches.iloc[0]['name'],
                description=matches.iloc[0]['description'],
                type=matches.iloc[0]['type'],
                use=matches.iloc[0]['use']
            )
        else:
            result = OCRResponse(error='ไม่พบข้อมูลตัวยา')
    else:
        # ตรวจสอบว่าข้อความเป็นภาษาไทยหรือไม่
        if not is_thai(filtered_text):
            return OCRResponse(error="ไม่พบข้อมูลตัวยา")

        processed_text = process_text(filtered_text)

        # ตรวจสอบความเหมือนของข้อความ OCR กับ df['description'] โดยใช้ cosine similarity
        vectorizer = TfidfVectorizer()
        vectors = vectorizer.fit_transform(df['description'].dropna().unique())
        ocr_vector = vectorizer.transform([processed_text])
        cosine_similarities = cosine_similarity(ocr_vector, vectors).flatten()
        highest_similarity_index = cosine_similarities.argmax()
        highest_similarity_value = cosine_similarities[highest_similarity_index]

        similarity_threshold = 0.3  # กำหนดค่า threshold ความเหมือนที่เหมาะสม

        if highest_similarity_value >= similarity_threshold:
            best_match = df['description'].dropna().unique()[highest_similarity_index]
            matches = df[df['description'].str.contains(best_match, case=False, na=False)]
        else:
            return OCRResponse(error="ไม่พบข้อมูลตัวยา")

        # ใช้โมเดลที่เทรนในการทำนายประเภทของข้อความที่ได้รับจาก OCR
        predicted_type = loaded_model.predict([processed_text])[0]

        # จับคู่และแสดงข้อมูลที่เกี่ยวข้องจาก CSV สำหรับ type ที่ทำนายได้
        matching_rows_loaded = df[df['type'] == predicted_type]

        if not matching_rows_loaded.empty:
            row = matching_rows_loaded.iloc[0]
            result = OCRResponse(
                type=row['type'],
                use=row['use']
            )
        else:
            result = OCRResponse(error="ไม่พบข้อมูลตัวยา")

    return result
#.................................................................................................................................




@app.post("/predictENG/")
async def predict(file: UploadFile = File(...)):
    # อ่านข้อมูลรูปภาพ
    try:
        content = await file.read()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read file: {e}")
    
    image = vision_v1.Image(content=content)

    # ตรวจจับข้อความในรูปภาพ
    response = client.text_detection(image=image)
    texts = response.text_annotations

    # ฟังก์ชันสำหรับประมวลผลข้อความ OCR
    def process_text(text):
        return ' '.join(text.split())

    # ฟังก์ชันสำหรับกรองเฉพาะตัวอักษรและตัวเลข
    def filter_alnum(text):
        return ''.join(filter(str.isalnum, text))
    
    def is_eng(text):
        return any('A' <= char <= 'Z' or 'a' <= char <= 'z' for char in text)

    # กรองและรวมข้อความจาก OCR
    ocr_texts = [filter_alnum(text.description) for text in texts if filter_alnum(text.description)]

    # ดึงข้อความ OCR และทำความสะอาด
    full_text1 = ','.join([text.description.replace(',', ' ') for text in texts])
    filtered_text = process_text(full_text1)
    cleaned_text = filtered_text.replace("  ", " ").replace(" ,", ",").replace(", ", ",")
    cleaned_text1 = re.sub(r',+', ',', cleaned_text)
    cleaned_text2 = re.sub(r'\.+', '', cleaned_text1)

    # แปลงข้อความเป็น vectors โดยใช้ TfidfVectorizer
    vectorizer = TfidfVectorizer()
    vectors = vectorizer.fit_transform(df3['name'].dropna().unique())
    ocr_vector = vectorizer.transform([' '.join(ocr_texts)])

    # คำนวณค่า cosine similarity ระหว่าง vectors
    cosine_similarities = cosine_similarity(ocr_vector, vectors).flatten()
    highest_similarity_index = cosine_similarities.argmax()
    highest_similarity_value = cosine_similarities[highest_similarity_index]

    # กำหนดค่า similarity ที่เหมาะสม
    similarity_threshold = 0.7
    if highest_similarity_value >= similarity_threshold:
        best_match = df3['name'].dropna().unique()[highest_similarity_index]
        matches = df3[df3['name'].str.contains(best_match, case=False, na=False)]
        
        if not matches.empty:
            result = matches.iloc[0][['name', 'use0', 'Therapeutic Class', 'sideEffect0']]
            return OCRResponse(
                name=result['name'],
                therapeutic_class=result['Therapeutic Class'],
                use0=result['use0'],
                side_effect0=result['sideEffect0']
            )
        else:
            result = OCRResponse(error='No match found in the dataset.')
        return result

    else:
        if not is_eng(full_text1):
            return OCRResponse(error='No match found in the dataset.')
        # สร้าง dataframe สำหรับการประมวลผลโมเดล

        df2 = pd.DataFrame(data1, columns=['use0', 'Therapeutic Class', 'sideEffect0'])
        df2['use0'] = df2['use0'].apply(lambda x: ','.join(str(x).split()))

        # แบ่งข้อมูล train/test
        X_train, X_test, y_train, y_test = train_test_split(df2['use0'], df2['Therapeutic Class'], test_size=0.2, random_state=42)

        # ใช้ Tokenizer เพื่อแปลงข้อความเป็นลำดับตัวเลข
        tokenizer = Tokenizer(num_words=7000)
        tokenizer.fit_on_texts(X_train)

        # แปลงข้อความเป็นลำดับและทำ padding
        max_length = 150
        X_train_seq = tokenizer.texts_to_sequences(X_train)
        X_test_seq = tokenizer.texts_to_sequences(X_test)
        X_train_padded = pad_sequences(X_train_seq, maxlen=max_length, padding='post')
        X_test_padded = pad_sequences(X_test_seq, maxlen=max_length, padding='post')

        # สร้างตัวแปลง LabelEncoder
        label_encoder = LabelEncoder()

        # แปลง y_train และ y_test เป็นตัวเลขและทำ One-Hot Encoding
        y_train = label_encoder.fit_transform(y_train)
        y_test = label_encoder.transform(y_test)
        y_train = to_categorical(y_train)
        y_test = to_categorical(y_test)

        # โหลดโมเดลจากไฟล์ .h5
        loaded_model = load_model('classifier.h5')

        # ทำนายประเภทของข้อความ OCR โดยใช้โมเดล
        ocr_seq = tokenizer.texts_to_sequences([cleaned_text2])
        ocr_padded = pad_sequences(ocr_seq, maxlen=max_length, padding='post')

        predicted_type_loaded = loaded_model.predict(ocr_padded)
        predicted_class_index = np.argmax(predicted_type_loaded, axis=-1)
        predicted_class = label_encoder.inverse_transform([predicted_class_index[0]])

        # # ตรวจสอบค่าความน่าจะเป็นของผลลัพธ์ที่ทำนายได้
        confidence_score = np.max(predicted_type_loaded)

        # # ตั้งค่าเกณฑ์ความมั่นใจ
        confidence_threshold = 0.7  # คุณสามารถปรับค่าเกณฑ์นี้ได้

        if confidence_score < confidence_threshold:
            return OCRResponse(error="medicine No data.")
    
        # ดึงค่าของคอลัมน์ use0 และ sideEffect1 จากแถวที่ตรงกับ Therapeutic Class ที่ทำนายได้
        matching_row = df2[df2['Therapeutic Class'] == predicted_class[0]]
        if not matching_row.empty:
            return OCRResponse(
                therapeutic_class=predicted_class[0],
                use0=matching_row.iloc[0]['use0'],
                # side_effect0=matching_row.iloc[0]['sideEffect0']
            )   
    return OCRResponse(error="medicine No data.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="172.20.10.2", port=8000)
