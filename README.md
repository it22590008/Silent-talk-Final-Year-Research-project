# " SILENT TALK " - A Real Time Communication System For Enhancing Dumb Communication Translating Sign Language

# Research Problem

According to the World Health Organization (WHO), more than 300 million people worldwide suffer from hearing impairments, while nearly one million individuals are unable to speak. These conditions significantly affect daily life, particularly in terms of effective communication with the hearing population.

Communication is a fundamental human need; however, deaf and mute individuals primarily depend on sign language, which is not commonly understood by most people. This creates major communication barriers in critical areas such as education, healthcare, emergency situations, and social interactions. Although technological solutions exist, most current mobile applications offer only limited gesture recognition and fail to support accurate, real-time sign language interpretation in practical, everyday scenarios.

The motivation for this research is to develop an AI-powered mobile application that bridges this communication gap through four core components. The first is a real-time dumb communication system that interprets sign language during live video interactions and converts it into text and voice output. The second component is a sign language tutor system designed to help non-deaf users learn and practice sign language interactively. The third component is an emergency support system that enables quick and reliable communication during urgent situations. The fourth component is a task-based sign language maths quiz system, which supports learning and cognitive development through interactive, sign-based activities.

By integrating these components into a single mobile platform, this research aims to enhance accessibility, promote social inclusion, and empower deaf and mute individuals through intelligent and inclusive mobile technology.

# Proposed Solution

To address the communication challenges faced by deaf and mute individuals, this research proposes an AI-powered mobile application that enables real-time, accessible, and inclusive communication using sign language recognition. The solution leverages modern computer vision and deep learning techniques to interpret sign language gestures captured through a smartphone camera and translate them into understandable forms for non-sign language users.

The proposed system integrates four key components into a single mobile platform. The Real-Time Dumb Communication System enables live communication between users by recognizing sign language gestures using a YOLOv8 model and converting them into real-time subtitles, synthesized voice output, and visual sign representations during video interactions. This allows seamless communication without the need for interpreters or manual text input.

The Sign Language Tutor System provides an interactive learning environment where non-deaf users can learn and practice sign language. Using real-time gesture recognition, the system offers immediate feedback, promoting better understanding and encouraging inclusive communication. The Emergency Support System enhances user safety by detecting predefined emergency sign gestures and automatically triggering alerts, ensuring quick and reliable communication in critical situations. Additionally, the Task-Based Sign Language Maths Quiz System supports cognitive development and learning through interactive, sign-based quizzes, making education more engaging and accessible.

The entire solution is implemented as a cross-platform mobile application using React Native, ensuring accessibility across devices. YOLOv8 is employed for its efficiency and accuracy in real-time object and gesture detection, while OpenCV handles video frame processing. Firebase supports user authentication, real-time data handling, and notifications. By combining real-time communication, learning, emergency support, and intelligent interaction within a single mobile platform, the proposed solution effectively bridges the communication gap between deaf and hearing individuals and contributes to the development of inclusive and assistive mobile technologies.


<img width="1248" height="832" alt="Overall diagram" src="https://github.com/user-attachments/assets/a75a4676-b0f8-467f-9bd6-6b6af6b6eda1" />


# Main Components

1. Real Time Communication Portal
2. Emergency Sign Detection & Alert System
3. Alphabet Tutor Component
4. Task-based sign language number learning system


# 1. Real Time Communication Portal

The Real-Time Dumb Communication System is the core component of the proposed mobile application, designed to enable seamless communication between deaf or mute users and hearing individuals. This component facilitates live, bidirectional interaction through intelligent sign language recognition and real-time translation.

To initiate communication, both users are required to register and log in to the system using secure authentication services. Once authenticated, users can access the communication portal, where they can view and select contacts from a registered users list. Upon selecting a user, a live communication session is established between the two parties.

During the communication session, the mobile device camera is activated to capture real-time video input of sign language gestures. These video frames are processed using OpenCV and passed to a YOLOv8-based deep learning model, which is trained to detect and classify sign language gestures with high accuracy. The recognized signs are then translated into corresponding textual representations and converted into natural voice output using text-to-speech mechanisms.

The translated content is presented to the receiving user through multiple modalities to enhance understanding and accessibility. This includes real-time subtitles, synthesized voice output, and a visual vector-based illustration representing the detected sign gesture. This multimodal feedback ensures effective comprehension even in noisy or visually constrained environments.

By integrating real-time gesture recognition, text translation, voice synthesis, and visual representation within a mobile platform, the Real-Time Dumb Communication System significantly reduces communication barriers and enables inclusive, natural interaction between sign language users and non-sign language users.



# 2. Emergency Sign Detection & Alert System

Mobile based emergency sign communication system for deaf users. It uses the mobile phone camera to recognize emergency hand signs using a YOLO trained model. The system allows users to create and save their own custom emergency signs. When a saved sign is detected, the app automatically sends a predefined alert message with time and location to selected contacts. The recognition works in real time and provides a fast, non-verbal way to request help during emergency situations. 



# 3. Alphabet Tutor Component

The Interactive Sign Language Tutor uses a YOLOv8-based AI model to detect hand gestures in real time through the mobile camera. The system shows a random alphabet and guides the learner to perform the correct sign. After detection, the tutor provides intelligent feedback by grading the gesture based on confidence and response time, not just “correct or wrong.” The component also tracks user performance, including accuracy, speed, and repeated mistakes, and visualizes progress over time. This allows learners to identify weak letters, monitor improvement, and receive personalized practice. By combining real-time sign detection with AI-driven assessment and progress tracking, the tutor transforms simple recognition into an adaptive learning experience.



# 4. Task-based sign language number learning system

Mobile phone-based number learning system for deaf children. It uses a camera to recognize hand signs for numbers using a YOLOv8-trained model. The system provides simple learning tasks using basic arithmetic operations, allows students to answer using hand signs, and checks answers in real time. Based on the recognition, it provides immediate feedback such as correction or retry, making number learning interactive and child-friendly.


# Project Members

1. Rathnasiri P.D.C  –  IT22590008
2. Wijerathne M.Y  –  IT22596116
3. Wijethunga J.S.H  –  IT22563996
4. Rathnayake R.M.C.G – IT22575630


