import os
import io
import pickle
import pandas as pd
import nltk
from google.cloud import vision_v1
from pythainlp import word_tokenize

# ดาวน์โหลด resource ของ NLTK
nltk.download('punkt')

# โหลดข้อมูลจากไฟล์ CSV
try:
    data = pd.read_csv('Book1.csv', encoding='utf-8', on_bad_lines='warn')
except UnicodeDecodeError:
    data = pd.read_csv('Book1.csv', encoding='ISO-8859-1', on_bad_lines='warn')

# ตั้งค่าคีย์ API ของ Google Cloud
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'project-service.json'
client = vision_v1.ImageAnnotatorClient()

# ตั้งค่าพาธของไฟล์รูปภาพ
file_name = 'k1.jpg'
image_folder = 'C:/Users/User/google_vision_ai_demo/'
image_path = os.path.join(image_folder, file_name)

# อ่านข้อมูลรูปภาพ
with io.open(image_path, 'rb') as image_file:
    content = image_file.read()

image = vision_v1.types.Image(content=content)

# ระบุคำใบ้ภาษา (ภาษาไทยและภาษาอังกฤษ)
image_context = vision_v1.types.ImageContext(
    language_hints=['th', 'en']
)

# ทำการตรวจจับข้อความในรูปภาพ
response = client.text_detection(image=image, image_context=image_context)
texts = response.text_annotations

# ฟังก์ชันสำหรับกรองเฉพาะตัวอักษรและตัวเลข รวมถึงภาษาไทย
def filter_alnum_thai(text):
    return ''.join(filter(lambda x: x.isalnum() or '\u0E00' <= x <= '\u0E7F', text))

# ฟังก์ชันสำหรับประมวลผลข้อความจาก OCR 
def process_text(text):
    tokens = nltk.word_tokenize(text)
    thai_tokens = word_tokenize(text, engine='newmm')
    return thai_tokens 

# รวมข้อความทั้งหมดที่ตรวจจับได้เป็นสตริงเดียวและลดช่องว่าง
full_text = ''.join([text.description.replace('\n', '').replace(' ', '') for text in texts][0]) 
filtered_full_text = filter_alnum_thai(full_text)
processed_text = process_text(filtered_full_text)

# บันทึกข้อความที่ประมวลผลแล้วลงในไฟล์ (pickle)
with open('processed_text.pkl', 'wb') as file:
    pickle.dump(processed_text, file)

# โหลดข้อความที่บันทึกไว้จากไฟล์
with open('processed_text.pkl', 'rb') as file:
    loaded_processed_text = pickle.load(file)

# แสดงข้อความที่ตรวจจับได้ทั้งหมด
print("Detected text descriptions:")
print(full_text)

# จับคู่และแสดงข้อมูลที่เกี่ยวข้องจาก CSV
print("\nMatching data from CSV:")
found_match = False  # ตัวแปรบันทึกสถานะการพบยาที่ตรงกัน

# เงื่อนไขแรก: ตรวจสอบจากคอลัมน์ 'name' ใน CSV
for text in texts:
    string_filtered = ''.join(filter(str.isalnum, text.description))
    if len(string_filtered) > 4 and 'name' in data.columns:
        matches = data[data['name'].str.contains(string_filtered, case=False, na=False)]
        if not matches.empty:
            print(matches)
            found_match = True
            break

# เงื่อนไขที่สอง: ตรวจสอบจากคอลัมน์ 'description' ใน CSV
if not found_match and len(filtered_full_text) > 4 and 'description' in data.columns:
    for index, row in data.iterrows():
        if any(keyword in processed_text for keyword in row['description'].split()):
            print("Matched:", row['type'])
            found_match = True
            break

# หากไม่พบยาตามทั้งสองเงื่อนไข
if not found_match:
    print("ไม่พบยา")
