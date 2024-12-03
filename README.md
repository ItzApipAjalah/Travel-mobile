# API Documentation for TravelEase Mobile

## 1. Authentication

Login:
POST http://127.0.0.1:8000/api/login

```json
Body: {
    "email": "user@example.com",
    "password": "password123"
}
```
```json
Response: {
    "status": true,
    "message": "Login successful",
    "data": {
        "token": "your_access_token",
        "user": {
            "id": 1,
            "name": "User Name",
            "email": "user@example.com",
            "type": "user"
        }
    }
}
```
## 2. Profile Management

Update Profile:
PUT http://127.0.0.1:8000/api/profile/update
```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Body: {
    "name": "New Name",
    "email": "newemail@example.com"
}
```

Change Password:
PUT http://127.0.0.1:8000/api/profile/password

```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Body: {
    "current_password": "old_password",
    "new_password": "new_password",
    "new_password_confirmation": "new_password"
}
```

## 3. Ticket Management
-----------------
Get All Tickets:
GET http://127.0.0.1:8000/api/tickets

```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Response: {
    "status": true,
    "message": "Tickets retrieved successfully",
    "data": [
        {
            "id": 1,
            "ticket_no": "123",
            "title": "Issue Title",
            "description": "Issue Description",
            "status": "pending/accepted/closed",
            "created_at": "timestamp",
            "user": {...},
            "category": {...}
        }
    ]
}
```

## 4. Chat/Messages

Get Messages for Ticket:
GET http://127.0.0.1:8000/api/tickets/{ticketId}/messages

```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Response: {
    "status": true,
    "message": "Messages retrieved successfully",
    "data": {
        "ticket_id": 5,
        "ticket_status": "accepted",
        "messages": [
            {
                "id": 4,
                "message": "Message content",
                "created_at": "timestamp",
                "user": {
                    "id": 2,
                    "name": "User Name",
                    "type": "user/officer"
                }
            }
        ]
    }
}
```

Send Message:
POST http://127.0.0.1:8000/api/tickets/{ticketId}/messages

```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Body: {
    "message": "Your message here"
}
```

## 5. FAQ/Conversation
----------------
Get Initial Conversation:
GET http://127.0.0.1:8000/api/conversation/initial

```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Response: {
    "success": true,
    "message": "Initial conversation nodes retrieved successfully",
    "data": {
        "question": "Main question",
        "nodes": [
            {
                "id": 1,
                "question": "Node question",
                "button_text": "Button text",
                "answer": "Answer or null"
            }
        ]
    }
}
```

Get Child Nodes:
GET http://127.0.0.1:8000/api/conversation/children/{parentId}

```json
Headers: {
    'Authorization': 'Bearer your_token'
}
```

```json
Response: {
    "success": true,
    "message": "Child nodes retrieved successfully",
    "data": {
        "question": "Parent question",
        "parent_answer": null,
        "nodes": [
            {
                "id": 6,
                "question": "Child question",
                "button_text": "Button text",
                "answer": "Answer text"
            }
        ]
    }
}
```
Notes:
- Selalu include bearer tokennya
