"""
API Testing Script - Tests all major endpoints
Run this after starting your FastAPI server to verify everything works
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

# Test data
TEST_USER = {
    "first_name": "Test",
    "last_name": "User",
    "email": f"test_{datetime.now().timestamp()}@example.com",
    "password_hash": "testpassword123",
    "date_of_birth": "2000-01-01",
    "gender": "other"
}

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    END = '\033[0m'

def print_test(test_name):
    print(f"\n{Colors.BLUE}Testing: {test_name}{Colors.END}")

def print_success(message):
    print(f"{Colors.GREEN}✓ {message}{Colors.END}")

def print_error(message):
    print(f"{Colors.RED}✗ {message}{Colors.END}")

def print_info(message):
    print(f"{Colors.YELLOW}ℹ {message}{Colors.END}")

class APITester:
    def __init__(self):
        self.token = None
        self.user_id = None
        self.headers = {}
        
    def test_health(self):
        print_test("Health Check")
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print_success("Server is healthy")
            return True
        print_error(f"Health check failed: {response.status_code}")
        return False
    
    def test_register(self):
        print_test("User Registration")
        response = requests.post(f"{BASE_URL}/auth/register", json=TEST_USER)
        
        if response.status_code == 201:
            data = response.json()
            self.user_id = data['id']
            print_success(f"User registered: ID {self.user_id}")
            return True
        print_error(f"Registration failed: {response.text}")
        return False
    
    def test_login(self):
        print_test("User Login")
        login_data = {
            "username": TEST_USER["email"],
            "password": TEST_USER["password_hash"]
        }
        response = requests.post(f"{BASE_URL}/auth/login", data=login_data)
        
        if response.status_code == 200:
            data = response.json()
            self.token = data.get('access_token')
            if self.token:
                self.headers = {"Authorization": f"Bearer {self.token}"}
                print_success("Login successful")
                print_info(f"Token: {self.token[:30]}...")
                print_info(f"User ID: {data.get('user_id')}")
                return True
            else:
                print_error(f"No token in response: {data}")
                return False
        print_error(f"Login failed: {response.status_code} - {response.text}")
        return False
    
    def test_get_current_user(self):
        print_test("Get Current User")
        response = requests.get(f"{BASE_URL}/auth/me", headers=self.headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"User info retrieved: {data['first_name']} {data['last_name']}")
            return True
        print_error(f"Get user failed: {response.text}")
        return False
    
    def test_mood_logging(self):
        print_test("Mood Logging")
        mood_data = {
            "mood": "happy",
            "note": "Feeling great today!"
        }
        response = requests.post(f"{BASE_URL}/moods/", json=mood_data, headers=self.headers)
        
        if response.status_code == 201:
            print_success("Mood logged successfully")
            
            # Test getting moods
            response = requests.get(f"{BASE_URL}/moods/", headers=self.headers)
            if response.status_code == 200:
                print_success(f"Retrieved {len(response.json())} mood logs")
            return True
        print_error(f"Mood logging failed: {response.text}")
        return False
    
    def test_mood_statistics(self):
        print_test("Mood Statistics")
        response = requests.get(f"{BASE_URL}/moods/statistics", headers=self.headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"Statistics: {data['total_entries']} entries")
            return True
        print_error(f"Statistics failed: {response.text}")
        return False
    
    def test_journal_entry(self):
        print_test("Journal Entry")
        journal_data = {
            "title": "My First Entry",
            "content": "This is a test journal entry about my day."
        }
        response = requests.post(f"{BASE_URL}/journals/", json=journal_data, headers=self.headers)
        
        if response.status_code == 201:
            print_success("Journal entry created")
            return True
        print_error(f"Journal creation failed: {response.text}")
        return False
    
    def test_todo(self):
        print_test("Todo Management")
        todo_data = {
            "task_text": "Test task",
            "is_completed": False
        }
        response = requests.post(f"{BASE_URL}/todos/", json=todo_data, headers=self.headers)
        
        if response.status_code == 201:
            todo_id = response.json()['id']
            print_success(f"Todo created: ID {todo_id}")
            
            # Complete the todo
            response = requests.post(f"{BASE_URL}/todos/{todo_id}/complete", headers=self.headers)
            if response.status_code == 200:
                print_success("Todo completed (XP awarded)")
            return True
        print_error(f"Todo creation failed: {response.text}")
        return False
    
    def test_characters(self):
        print_test("Character System")
        
        # Get all characters
        response = requests.get(f"{BASE_URL}/characters/")
        if response.status_code == 200:
            characters = response.json()
            print_success(f"Found {len(characters)} characters")
            
            if characters:
                # Choose first character
                char_id = characters[0]['id']
                response = requests.post(
                    f"{BASE_URL}/characters/me/choose/{char_id}",
                    headers=self.headers
                )
                if response.status_code == 201:
                    print_success(f"Chose character: {characters[0]['name']}")
                return True
        print_error("Character test failed")
        return False
    
    def test_character_mood_state(self):
        print_test("Character Mood State")
        response = requests.get(f"{BASE_URL}/characters/me/mood-state", headers=self.headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"Mood score: {data['mood_score']}")
            print_info(f"Character state: {data['character_state']}")
            print_info(f"Environment: {data['environment']}")
            return True
        print_error(f"Mood state check failed: {response.text}")
        return False
    
    def test_achievements(self):
        print_test("Achievement System")
        
        # Check achievements
        response = requests.post(f"{BASE_URL}/achievements/me/check", headers=self.headers)
        if response.status_code == 200:
            print_success("Achievement check completed")
            
            # Get user achievements
            response = requests.get(f"{BASE_URL}/achievements/me/achievements", headers=self.headers)
            if response.status_code == 200:
                achievements = response.json()
                print_success(f"Unlocked {len(achievements)} achievements")
            return True
        print_error("Achievement test failed")
        return False
    
    def test_streak(self):
        print_test("Streak Calculation")
        response = requests.get(f"{BASE_URL}/achievements/me/streak", headers=self.headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"Current streak: {data['current_streak']} days")
            return True
        print_error("Streak calculation failed")
        return False
    
    def test_rewards(self):
        print_test("Reward System")
        
        # Get available rewards
        response = requests.get(f"{BASE_URL}/rewards/me/available", headers=self.headers)
        if response.status_code == 200:
            rewards = response.json()
            print_success(f"Found {len(rewards)} affordable rewards")
            
            if rewards:
                # Try to unlock first reward
                reward_id = rewards[0]['id']
                response = requests.post(
                    f"{BASE_URL}/rewards/me/unlock/{reward_id}",
                    headers=self.headers
                )
                if response.status_code == 200:
                    result = response.json()
                    if result['success']:
                        print_success(f"Unlocked reward: {rewards[0]['name']}")
                    else:
                        print_info(f"Cannot unlock: {result['message']}")
            return True
        print_error("Reward test failed")
        return False
    
    def test_collection_stats(self):
        print_test("Collection Statistics")
        response = requests.get(f"{BASE_URL}/rewards/me/collection-stats", headers=self.headers)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"Collection: {data['completion_percentage']}% complete")
            print_info(f"Unlocked: {data['total_unlocked']}/{data['total_available']}")
            return True
        print_error("Collection stats failed")
        return False
    
    def test_interests(self):
        print_test("Interest System")
        
        # Get all interests
        response = requests.get(f"{BASE_URL}/interests/")
        if response.status_code == 200:
            interests = response.json()
            print_success(f"Found {len(interests)} interests")
            
            if interests:
                # Add interest to user
                interest_id = interests[0]['id']
                response = requests.post(
                    f"{BASE_URL}/users/me/interests/{interest_id}",
                    headers=self.headers
                )
                if response.status_code == 201:
                    print_success(f"Added interest: {interests[0]['name']}")
            return True
        print_error("Interest test failed")
        return False
    
    def test_journal_prompts(self):
        print_test("Journal Prompts")
        
        # Get daily prompt
        response = requests.get(f"{BASE_URL}/journal-prompts/daily", headers=self.headers)
        if response.status_code == 200:
            prompt = response.json()
            print_success(f"Got daily prompt: {prompt['prompt_text'][:50]}...")
            
            # Get random prompt
            response = requests.get(f"{BASE_URL}/journal-prompts/random")
            if response.status_code == 200:
                print_success("Random prompt retrieved")
            return True
        print_error("Prompt test failed")
        return False
    
    def run_all_tests(self):
        print("\n" + "="*60)
        print("STARTING API ENDPOINT TESTS")
        print("="*60)
        
        tests = [
            ("Health Check", self.test_health),
            ("User Registration", self.test_register),
            ("User Login", self.test_login),
            ("Get Current User", self.test_get_current_user),
            ("Mood Logging", self.test_mood_logging),
            ("Mood Statistics", self.test_mood_statistics),
            ("Journal Entry", self.test_journal_entry),
            ("Todo Management", self.test_todo),
            ("Characters", self.test_characters),
            ("Character Mood State", self.test_character_mood_state),
            ("Achievements", self.test_achievements),
            ("Streak Calculation", self.test_streak),
            ("Rewards", self.test_rewards),
            ("Collection Stats", self.test_collection_stats),
            ("Interests", self.test_interests),
            ("Journal Prompts", self.test_journal_prompts),
        ]
        
        passed = 0
        failed = 0
        
        for test_name, test_func in tests:
            try:
                if test_func():
                    passed += 1
                else:
                    failed += 1
            except Exception as e:
                print_error(f"Exception in {test_name}: {e}")
                failed += 1
        
        print("\n" + "="*60)
        print("TEST RESULTS")
        print("="*60)
        print(f"{Colors.GREEN}Passed: {passed}{Colors.END}")
        print(f"{Colors.RED}Failed: {failed}{Colors.END}")
        print(f"Total: {passed + failed}")
        print("="*60 + "\n")

if __name__ == "__main__":
    tester = APITester()
    tester.run_all_tests()