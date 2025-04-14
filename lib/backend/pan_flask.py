from flask import Flask, request, jsonify
from flask_cors import CORS
import http.client
import json
import time
import logging

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.DEBUG)

# Constants for API credentials
ACCOUNT_ID = "9bc6bafe2797/e43d98ed-b075-402e-a8c4-5b390367d0b6"
API_KEY = "ea69a5a0-e822-4a64-ac5a-06a2b928c57f"

def verify_pan(pan_number, full_name, dob):
    conn = http.client.HTTPSConnection("eve.idfy.com")
    payload = json.dumps({
            "task_id": "ind_pan",
            "group_id": "ind_pan",
            "data": {
                "id_number": pan_number,
                "full_name": full_name,
                "dob": dob
            }
        })
    logging.debug("Sending request to IDfy API with payload: %s", payload)
    headers = {
        'Content-Type': 'application/json',
        'account-id': ACCOUNT_ID,
        'api-key': API_KEY
    }
    conn.request("POST", "/v3/tasks/async/verify_with_source/ind_pan", payload, headers)
    res = conn.getresponse()
    data = res.read()
    response = json.loads(data.decode("utf-8"))
    logging.debug("Received response from IDfy API: %s", response)
    
    if 'status' in response and response['status'] == 'error':
        raise Exception(response.get('message', 'Unknown error from IDfy API'))
        
    return response.get("request_id")

def check_status(request_id):
    conn = http.client.HTTPSConnection("eve.idfy.com")
    headers = {
        'Content-Type': 'application/json',
        'api-key': API_KEY,
        'account-id': ACCOUNT_ID
    }
    conn.request("GET", f"/v3/tasks?request_id={request_id}", '', headers)
    res = conn.getresponse()
    data = res.read()
    response = json.loads(data.decode("utf-8"))
    logging.debug("Status check response: %s", response)
    return response

@app.route('/verify-pan', methods=['POST'])
def verify_pan_api():
    try:
        data = request.get_json()
        pan_number = data.get('pan_number')
        full_name = data.get('full_name')
        dob = data.get('dob')
        
        logging.info("Received request with data: %s", {'pan_number': pan_number, 'full_name': full_name, 'dob': dob})
        
        if not (pan_number and full_name and dob):
            return jsonify({'error': 'Missing required fields'}), 400

        request_id = verify_pan(pan_number, full_name, dob)
        if not request_id:
            logging.error("No request_id received from verify_pan")
            return jsonify({
                'status': 'error',
                'message': 'Verification request failed',
                'details': 'No request ID received from verification service'
            }), 500

        # Wait for processing (adjust sleep duration as needed)
        time.sleep(5)
        
        # Try getting status up to 3 times
        max_retries = 3
        for attempt in range(max_retries):
            result = check_status(request_id)
            logging.debug(f"Status check attempt {attempt + 1}: {result}")
            
            if result and isinstance(result, list) and len(result) > 0:
                verification_result = result[0]
                
                if verification_result.get('status') == 'completed':
                    source_output = verification_result.get('result', {}).get('source_output', {})
                    
                    # Log the complete source output for debugging
                    logging.debug("Source output: %s", source_output)
                    
                    pan_status = source_output.get('pan_status', '')
                    
                    # If PAN exists and is valid, show verified
                    if "Existing and Valid" in pan_status:
                        return jsonify({
                            'status': 'success',
                            'message': 'PAN Verified Successfully',
                            'details': 'Your PAN is valid and active.'
                        })
                    else:
                        return jsonify({
                            'status': 'error',
                            'message': 'Verification Failed',
                            'details': f"PAN status: {pan_status if pan_status else 'Invalid'}"
                        })
                elif verification_result.get('status') == 'failed':
                    return jsonify({
                        'status': 'error',
                        'message': 'Verification Failed',
                        'details': verification_result.get('message', 'Unknown error occurred')
                    })
                elif attempt < max_retries - 1:
                    time.sleep(2)  # Wait before retrying
                    continue
            
            if attempt == max_retries - 1:
                return jsonify({
                    'status': 'error',
                    'message': 'Verification Timeout',
                    'details': 'Verification is taking longer than expected. Please try again.'
                })
                
    except Exception as e:
        logging.exception("An error occurred during PAN verification")
        return jsonify({
            'status': 'error',
            'message': 'Verification Failed',
            'details': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)