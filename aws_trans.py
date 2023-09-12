import boto3

# Replace 'YOUR_AWS_ACCESS_KEY' and 'YOUR_AWS_SECRET_KEY' with your actual AWS credentials
aws_access_key = 'AKIA2VWWOM5WJGEXC3BN'
aws_secret_key = 'JDZS6h101clEw/Hdk75uK943z1LJOlapVVSBNw4S'

# Create an Amazon Translate client
translate = boto3.client('translate', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name='us-east-1')  # Replace 'us-west-2' with your desired AWS region

def translate_to_cantonese(text):
    response = translate.translate_text(
        Text=text,
        SourceLanguageCode='auto',  # Automatically detect the source language
        TargetLanguageCode='es'  # 'zh-Hant' is the language code for Traditional Chinese (Cantonese)
    )
    return response['SourceLanguageCode'], response['TranslatedText']

word_to_translate = "Hello, what time is it?"  # Replace with the word you want to translate
input_language, translated_text = translate_to_cantonese(word_to_translate)

print(f"Input Text (Language: {input_language}): {word_to_translate}")
print(f"Translated Text (Cantonese): {translated_text}")
