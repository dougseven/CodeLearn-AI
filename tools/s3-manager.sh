#!/bin/bash

source config/dev-config.sh

function show_help {
    echo "S3 Bucket Manager"
    echo "================="
    echo ""
    echo "Usage: ./s3-manager.sh <command>"
    echo ""
    echo "Commands:"
    echo "  list-lessons     - List all static lessons"
    echo "  list-frontend    - List frontend files"
    echo "  sync-lessons     - Upload local lessons to S3"
    echo "  sync-frontend    - Upload frontend to S3"
    echo "  clean-lessons    - Remove all static lessons"
    echo "  info             - Show bucket information"
}

function list_lessons {
    echo "📚 Static Lessons in S3:"
    echo "========================"
    aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive --human-readable
}

function list_frontend {
    echo "🌐 Frontend Files in S3:"
    echo "======================="
    aws s3 ls s3://$FRONTEND_BUCKET/ --recursive --human-readable
}

function sync_lessons {
    if [ ! -d "static_lessons" ]; then
        echo "❌ static_lessons directory not found"
        exit 1
    fi
    
    echo "📤 Syncing lessons to S3..."
    aws s3 sync static_lessons/ s3://$STATIC_LESSONS_BUCKET/static/ --delete
    echo "✅ Sync complete"
}

function sync_frontend {
    if [ ! -d "frontend" ]; then
        echo "❌ frontend directory not found"
        exit 1
    fi
    
    echo "📤 Syncing frontend to S3..."
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ --delete
    echo "✅ Sync complete"
    echo ""
    echo "Frontend URL: $FRONTEND_URL"
}

function clean_lessons {
    echo "⚠️  This will delete ALL static lessons from S3"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        aws s3 rm s3://$STATIC_LESSONS_BUCKET/static/ --recursive
        echo "✅ All lessons deleted"
    else
        echo "❌ Cancelled"
    fi
}

function show_info {
    echo "S3 Bucket Information"
    echo "===================="
    echo ""
    echo "Static Lessons Bucket:"
    echo "  Name: $STATIC_LESSONS_BUCKET"
    echo "  URL: s3://$STATIC_LESSONS_BUCKET"
    
    SIZE=$(aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive --summarize | grep "Total Size" | awk '{print $3}')
    COUNT=$(aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive --summarize | grep "Total Objects" | awk '{print $3}')
    
    echo "  Files: $COUNT"
    echo "  Size: $SIZE bytes"
    echo ""
    echo "Frontend Bucket:"
    echo "  Name: $FRONTEND_BUCKET"
    echo "  Website URL: $FRONTEND_URL"
}

# Main script
case "$1" in
    list-lessons)
        list_lessons
        ;;
    list-frontend)
        list_frontend
        ;;
    sync-lessons)
        sync_lessons
        ;;
    sync-frontend)
        sync_frontend
        ;;
    clean-lessons)
        clean_lessons
        ;;
    info)
        show_info
        ;;
    *)
        show_help
        ;;
esac
