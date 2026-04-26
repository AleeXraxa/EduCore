import os
import re

def replace_in_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace 'Rs. ' with 'PKR '
    content = content.replace("'Rs. '", "'PKR '")
    content = content.replace('"Rs. "', '"PKR "')
    
    # Replace Rs. with PKR in strings
    content = content.replace("Rs. ", "PKR ")
    content = content.replace("(Rs.)", "(PKR)")
    
    # Fix specifically for expenses_view.dart which uses \$
    content = content.replace("symbol: '\\$'", "symbol: 'PKR '")
    content = content.replace("symbol: \"\\$\"", "symbol: \"PKR \"")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    base_dir = 'lib/src'
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith('.dart'):
                replace_in_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
