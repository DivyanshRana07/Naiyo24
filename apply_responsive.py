#!/usr/bin/env python3
"""
Script to apply responsive design patterns to Flutter files.
This updates dart files to use responsive sizing utilities.
"""

import os
import re
from pathlib import Path

# Base path to Flutter project
FLUTTER_PROJECT = Path(r"C:\Users\NITRO\Desktop\Naiyo\Naiyo24\naiyo24_business_tool")

# Patterns to replace with responsive alternatives
REPLACEMENTS = [
    # EdgeInsets patterns
    (r'const EdgeInsets\.all\((\d+(?:\.\d+)?)\)', 
     r'context.responsive.padding(all: \1)'),
    (r'const EdgeInsets\.symmetric\(horizontal:\s*(\d+(?:\.\d+)?),\s*vertical:\s*(\d+(?:\.\d+)?)\)',
     r'context.responsive.padding(horizontal: \1, vertical: \2)'),
    (r'const EdgeInsets\.symmetric\(horizontal:\s*(\d+(?:\.\d+)?)\)',
     r'context.responsive.padding(horizontal: \1)'),
    (r'const EdgeInsets\.symmetric\(vertical:\s*(\d+(?:\.\d+)?)\)',
     r'context.responsive.padding(vertical: \1)'),
    (r'const EdgeInsets\.only\(([^)]+)\)',
     lambda m: f'context.responsive.padding({m.group(1)})'),
    
    # Padding widget patterns
    (r'padding:\s*const EdgeInsets\.all\(AppSpacing\.(\w+)\)',
     r'padding: context.responsive.padding(all: AppSpacing.\1)'),
    
    # BorderRadius patterns
    (r'BorderRadius\.circular\((\d+(?:\.\d+)?)\)',
     r'BorderRadius.circular(context.responsive.borderRadius(\1))'),
    (r'BorderRadius\.circular\(AppBorderRadius\.(\w+)\)',
     r'BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.\1))'),
    
    # Icon size patterns
    (r'size:\s*(\d+(?:\.\d+)?)[,\s]',
     r'size: context.responsive.iconSize(\1),'),
    
    # Font size in TextStyle
    (r'fontSize:\s*(\d+(?:\.\d+)?)[,\s]',
     r'fontSize: context.responsive.fontSize(\1),'),
    
    # SizedBox patterns
    (r'const SizedBox\(width:\s*(\d+(?:\.\d+)?)\)',
     r'SizedBox(width: context.responsive.spacing(\1))'),
    (r'const SizedBox\(height:\s*(\d+(?:\.\d+)?)\)',
     r'SizedBox(height: context.responsive.spacing(\1))'),
    (r'const SizedBox\(width:\s*AppSpacing\.(\w+)\)',
     r'SizedBox(width: context.responsive.spacing(AppSpacing.\1))'),
    (r'const SizedBox\(height:\s*AppSpacing\.(\w+)\)',
     r'SizedBox(height: context.responsive.spacing(AppSpacing.\1))'),
]

def needs_builder_wrapper(content):
    """Check if content needs Builder wrapper for context access"""
    return 'context.responsive' in content and 'Builder(' not in content[:200]

def process_file(file_path):
    """Process a single Dart file to add responsive sizing"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply replacements
        for pattern, replacement in REPLACEMENTS:
            if callable(replacement):
                content = re.sub(pattern, replacement, content)
            else:
                content = re.sub(pattern, replacement, content)
        
        # Check if any changes were made
        if content == original_content:
            return False, "No changes needed"
        
        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True, f"Updated {file_path.name}"
    
    except Exception as e:
        return False, f"Error processing {file_path.name}: {str(e)}"

def main():
    """Main function to process all Flutter files"""
    print("🚀 Starting responsive design update...\n")
    
    # Directories to process
    directories = [
        FLUTTER_PROJECT / "lib" / "screens",
        FLUTTER_PROJECT / "lib" / "widgets" / "common",
        FLUTTER_PROJECT / "lib" / "widgets" / "dashboard",
        FLUTTER_PROJECT / "lib" / "widgets" / "invoice",
        FLUTTER_PROJECT / "lib" / "widgets" / "quotation",
        FLUTTER_PROJECT / "lib" / "widgets" / "customer",
        FLUTTER_PROJECT / "lib" / "widgets" / "vendor",
        FLUTTER_PROJECT / "lib" / "widgets" / "item",
        FLUTTER_PROJECT / "lib" / "widgets" / "onboarding",
    ]
    
    total_files = 0
    updated_files = 0
    
    for directory in directories:
        if not directory.exists():
            print(f"⚠️  Directory not found: {directory}")
            continue
        
        print(f"📁 Processing {directory.name}/")
        
        for dart_file in directory.glob("*.dart"):
            total_files += 1
            success, message = process_file(dart_file)
            if success:
                updated_files += 1
                print(f"  ✅ {message}")
    
    print(f"\n{'='*50}")
    print(f"📊 Summary:")
    print(f"  Total files processed: {total_files}")
    print(f"  Files updated: {updated_files}")
    print(f"  Files unchanged: {total_files - updated_files}")
    print(f"{'='*50}\n")
    
    print("✨ Responsive design update complete!")
    print("\n⚠️  IMPORTANT: Manual review needed for:")
    print("  1. Files with complex nested widgets")
    print("  2. Build methods needing Builder() wrappers")
    print("  3. StatefulWidget widgets using context in initState()")
    
if __name__ == "__main__":
    main()
