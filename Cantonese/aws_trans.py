import boto3

# Replace 'YOUR_AWS_ACCESS_KEY' and 'YOUR_AWS_SECRET_KEY' with your actual AWS credentials
s3 = boto3.resource('s3')
# Create an Amazon Translate client
#translate = boto3.client('translate', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name='us-east-1')  # Replace 'us-west-2' with your desired AWS region
translate = boto3.client('translate', region_name='us-east-1')  # Replace 'us-west-2' with your desired AWS region
def translate_to_english(text):
    response = translate.translate_text(
        Text=text,
        SourceLanguageCode='zh-TW',  # Automatically detect the source language
        TargetLanguageCode='en-GB'  # 'zh-Hant' is the language code for Traditional Chinese (Cantonese)
    )
    return response['SourceLanguageCode'], response['TranslatedText']

content = ""

# Open the file for reading
with open('hws.txt', 'r') as file:
    # Iterate through the file line by line
    for line in file:
        # Append each line to the content variable
        content = line

#word_to_translate = "<hw eid='13324_hw_1' >阿崩劏羊</hw> <hw eid='11671_hw_1' >阿B</hw> <hw eid='12652_hw_1' >阿邊個</hw> <hw eid='10545_hw_1' >阿B仔</hw> <hw eid='09270_hw_1' >椏杈</hw> <hw eid='00040_hw_1' >阿差</hw> <hw eid='00041_hw_1' >阿燦</hw> <hw eid='10927_hw_1' >阿大</hw> <hw eid='08597_hw_1' >阿頂</hw> <hw eid='11716_hw_1' >阿飛</hw> <hw eid='00005_hw_1' >阿肥</hw> <hw eid='00014_hw_1' >阿福</hw> <hw eid='08207_hw_1' >丫撬</hw>"
        input_language, translated_text = translate_to_english(content)

        print(f"Input Text (Language: HW): {content}")
        print(f"Translated Text (English): {translated_text}")
