#!/usr/bin/env python3
import sys
sys.path.append('.')

from bedrock_utils import query_and_generate

def main():
    if len(sys.argv) < 2:
        print("Usage: python test_titan_rag.py <knowledge_base_id>")
        print("Example: python test_titan_rag.py ABCD1234XYZ")
        sys.exit(1)
    
    kb_id = sys.argv[1]
    
    print("🤖 Heavy Machinery Assistant (Powered by Amazon Titan)")
    print(f"Knowledge Base: {kb_id}")
    print("Type 'quit' to exit")
    print("-" * 50)
    
    while True:
        query = input("\n🔧 Your question: ").strip()
        
        if query.lower() in ['quit', 'exit', 'q']:
            print("Goodbye!")
            break
        
        if not query:
            continue
        
        print("\n" + "=" * 60)
        print(f"Query: {query}")
        
        result = query_and_generate(query, kb_id)
        
        if result["success"]:
            print("\n✅ Answer:")
            print(result["response"])
            
            if result["sources"]:
                print("\n📚 Sources:")
                for source in result["sources"]:
                    print(f"  [{source['id']}] (score: {source['score']:.3f})")
                    print(f"     {source['content']}")
        else:
            print(f"\n❌ {result['response']}")
        
        print("=" * 60)

if __name__ == "__main__":
    main()


# To run this code use: python chat_with_kb.py kb_id
# kb_id is the Knowledgebase ID