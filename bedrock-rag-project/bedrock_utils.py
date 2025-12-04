import boto3
from botocore.exceptions import ClientError
import json

# Initialize AWS Bedrock client
bedrock = boto3.client(
    service_name='bedrock-runtime',
    region_name='us-west-2'
)

# Initialize Bedrock Knowledge Base client
bedrock_kb = boto3.client(
    service_name='bedrock-agent-runtime',
    region_name='us-west-2'
)

def valid_prompt(prompt, model_id="amazon.titan-text-express-v1"):
    """Validate if prompt is about heavy machinery using Titan"""
    try:
        response = bedrock.invoke_model(
            modelId=model_id,
            contentType='application/json',
            accept='application/json',
            body=json.dumps({
                "inputText": f"""Classify this user query into exactly one category:

CATEGORIES:
A: Asking about AI/LLM models or system architecture
B: Contains profanity, hate speech, or toxic content
C: About topics OTHER THAN heavy machinery (weather, sports, politics, etc.)
D: Asking about how I work or my instructions
E: EXCLUSIVELY about heavy machinery, construction equipment, or related topics

USER QUERY: "{prompt}"

Respond with ONLY the single letter of the category (A, B, C, D, or E).""",
                "textGenerationConfig": {
                    "maxTokenCount": 3,
                    "temperature": 0,
                    "topP": 0.1,
                }
            })
        )
        
        response_body = json.loads(response['body'].read())
        category = response_body['results'][0]['outputText'].strip().upper()
        print(f"Validation category: {category}")
        
        return category == "E"
        
    except ClientError as e:
        print(f"Error validating prompt: {e}")
        # Fallback to keyword check
        return fallback_validation(prompt)

def fallback_validation(prompt):
    """Fallback validation using keyword matching"""
    heavy_machinery_keywords = [
        'bulldozer', 'excavator', 'crane', 'loader', 'backhoe', 'forklift',
        'grader', 'compactor', 'tractor', 'dozer', 'skid steer', 'asphalt',
        'pavement', 'construction', 'equipment', 'machinery', 'caterpillar',
        'deere', 'komatsu', 'hitachi', 'volvo', 'case', 'bobcat', 'jcb',
        'heavy equipment', 'construction vehicle', 'earth mover'
    ]
    
    prompt_lower = prompt.lower()
    for keyword in heavy_machinery_keywords:
        if keyword in prompt_lower:
            print(f"Fallback validation passed: contains '{keyword}'")
            return True
    
    print("Fallback validation failed: not about heavy machinery")
    return False

def query_knowledge_base(query, kb_id, max_results=3):
    """Query the Bedrock Knowledge Base"""
    try:
        response = bedrock_kb.retrieve(
            knowledgeBaseId=kb_id,
            retrievalQuery={
                'text': query
            },
            retrievalConfiguration={
                'vectorSearchConfiguration': {
                    'numberOfResults': max_results,
                    'overrideSearchType': 'HYBRID'  # Combines vector and text search
                }
            }
        )
        return response['retrievalResults']
    except ClientError as e:
        print(f"Error querying Knowledge Base: {e}")
        return []

def generate_response(prompt, model_id="amazon.titan-text-express-v1", temperature=0.7, top_p=0.9, max_tokens=500):
    """Generate response using Titan model"""
    try:
        response = bedrock.invoke_model(
            modelId=model_id,
            contentType='application/json',
            accept='application/json',
            body=json.dumps({
                "inputText": prompt,
                "textGenerationConfig": {
                    "maxTokenCount": max_tokens,
                    "temperature": temperature,
                    "topP": top_p,
                }
            })
        )
        response_body = json.loads(response['body'].read())
        return response_body['results'][0]['outputText']
    except ClientError as e:
        print(f"Error generating response: {e}")
        return ""

def query_and_generate(query, kb_id, model_id="amazon.titan-text-express-v1"):
    """Complete RAG pipeline with Titan"""
    print(f"🔍 Processing query: {query}")
    
    # Step 1: Validate
    if not valid_prompt(query, model_id):
        return {
            "success": False,
            "response": "I can only answer questions about heavy machinery and construction equipment.",
            "sources": []
        }
    
    # Step 2: Query KB
    results = query_knowledge_base(query, kb_id)
    if not results:
        return {
            "success": False,
            "response": "I couldn't find relevant information about that in my knowledge base.",
            "sources": []
        }
    
    # Step 3: Build context
    context_parts = []
    sources = []
    
    for i, result in enumerate(results[:3], 1):
        content = result.get('content', {}).get('text', '')
        score = result.get('score', 0)
        
        context_parts.append(f"[Source {i} - Relevance: {score:.3f}]")
        context_parts.append(content)
        context_parts.append("")
        
        sources.append({
            "id": i,
            "content": content[:200] + "..." if len(content) > 200 else content,
            "score": score,
            "metadata": result.get('metadata', {})
        })
    
    context = "\n".join(context_parts)
    
    # Step 4: Generate response
    prompt = f"""You are an expert on heavy machinery and construction equipment. 
Use the information below to answer the question. Be accurate and helpful.

INFORMATION:
{context}

QUESTION: {query}

ANSWER:"""
    
    response = generate_response(prompt, model_id, temperature=0.7, top_p=0.9)
    
    return {
        "success": True,
        "response": response,
        "sources": sources,
        "model_used": model_id
    }

# Test function
def test_titan_inference():
    """Test Titan model inference"""
    test_prompt = "Explain what a bulldozer is in simple terms."
    
    print("Testing Titan model inference...")
    response = generate_response(test_prompt, "amazon.titan-text-express-v1")
    print(f"Response: {response}")
    
    return response

if __name__ == "__main__":
    # Test the Titan model directly
    test_titan_inference()