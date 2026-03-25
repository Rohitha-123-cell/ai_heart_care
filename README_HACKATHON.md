# AI Health Guardian - Hackathon Preparation Guide

## Overview
This README is your quick preparation file for the hackathon. Use it to revise the project, practice your explanation, and prepare your demo flow.

AI Health Guardian is a responsive healthtech application built with Flutter. It combines symptom guidance, patient-data visualization, disease trend analytics, and skin-condition awareness into one platform powered by Gemini AI and local/backend health data.

## One-Line Pitch
AI Health Guardian is a smart healthtech platform that helps users understand symptoms, track personal health trends, analyze disease patterns, and get AI-assisted skin awareness support in one responsive app.

## Problem Statement Fit
This project now clearly covers these blueprint-style modules:

1. Symptom Checker Tool
2. Patient Data Visualization
3. Disease Trend Dashboard
4. Skin Condition Classifier

## Core Features You Should Mention
### 1. Symptom Checker
- users select symptoms or type additional symptoms
- Gemini helps generate likely guidance and caution-aware output
- useful for early awareness and first-level health support

### 2. Patient Data Visualization
- dashboard visualizes BMI, sleep, steps, heart risk, and related health values
- charts help identify trends over time instead of isolated numbers
- useful for monitoring and preventive health awareness

### 3. Disease Trend Dashboard
- local dataset is filtered by disease, region, and time window
- charts show spikes, peaks, region comparison, and abnormal days
- Gemini generates a quick trend summary from selected data

### 4. Skin Condition Classifier
- user uploads or captures an image
- Gemini analyzes visible skin-condition clues
- output is awareness-oriented and easy to understand

### 5. Extra Features That Strengthen the Demo
- AI health chatbot
- heart risk calculator
- health report generation
- medicine scanner
- emergency workflow
- nearby hospitals
- profile and dashboard experience

## Technology Stack
- Flutter for cross-platform responsive UI
- Supabase for authentication and backend-connected data
- Gemini API for text + image understanding
- FL Chart for trend visualizations
- Image Picker and camera flows for image-based features
- BLoC and service-based architecture for structured logic

## Where Gemini Is Used
- symptom analysis
- skin image analysis
- medicine explanation
- disease trend summary
- chatbot guidance

## What Not to Claim
Do not tell judges or users that this is a clinically validated medical diagnosis system unless you have real validation data.

Safe wording:
- "This is an AI-assisted health awareness prototype."
- "It is designed for guidance, visualization, and early support."
- "It does not replace a doctor or certified diagnostic system."

## Accuracy Answer for Judges
If they ask, "How accurate is your model?", say:

> This is a prototype and we do not claim medical-grade diagnostic accuracy yet. Our current focus is useful health guidance, visual awareness, and AI-assisted support. For real deployment, each module would need separate validation on medical datasets.

## Main Demo Flow
Use this order during presentation:

1. Start from the dashboard
2. Explain the project in one sentence
3. Open symptom checker and show a simple example
4. Open patient data charts and explain trend visualization
5. Open disease trend dashboard, apply filters, and generate Gemini summary
6. Open skin-condition classifier and show image analysis
7. Mention reports, emergency support, and medicine scanning as added impact

## Suggested 2-Minute Presentation Flow
### Opening
Problem:
- many people cannot quickly interpret symptoms, daily vitals, or health changes
- health information is often fragmented and hard to understand

Solution:
- we built one platform that combines symptom analysis, visual trend tracking, disease analytics, and AI image support

Impact:
- helps with early awareness, health education, and preventive monitoring

### Middle
Highlight these 4 modules:
- symptom checker
- patient data visualization
- disease trend dashboard
- skin condition classifier

### Closing
- this project shows how AI + visualization can make health information more accessible
- our prototype is scalable and can later connect to live datasets, wearables, and telemedicine workflows

## Short Stage Script
Use this if you need a compact explanation:

> We built AI Health Guardian, a responsive healthtech application that brings together symptom checking, personal health visualization, disease trend analytics, and skin-condition awareness in one place. Instead of giving users raw numbers, we help them understand health signals through charts, AI summaries, and guided interfaces. Gemini AI powers the reasoning and image understanding, while Flutter gives us a clean cross-platform experience.

## Likely Judge Questions and Answers
### Why is this project important?
Because many users need simple, fast, understandable health guidance before they can access professional care.

### Why is this different from a normal chatbot?
Because it combines structured symptom input, visual patient data, trend charts, and image-based analysis in one workflow.

### Why did you use Gemini?
Because it supports both text and image understanding, so we can reuse one strong AI layer across multiple health modules.

### Is this a replacement for doctors?
No. It is a support and awareness tool, not a clinical diagnosis platform.

### What is innovative here?
The integration of four different healthtech blueprints in one responsive and usable app.

## What You Must Learn Before the Hackathon
- the one-line pitch
- the 4 blueprint modules
- where Gemini is used
- the exact demo order
- what to say about accuracy
- what not to promise

## Module-to-Feature Mapping
| Blueprint Module | Project Feature |
|---|---|
| Symptom Checker Tool | Symptom Checker screen |
| Patient Data Visualization | Dashboard + Health Charts |
| Disease Trend Dashboard | Disease Trend Dashboard screen |
| Skin Condition Classifier | Camera / Skin Detection screen |

## Preparation Checklist
- [ ] app runs correctly in Chrome
- [ ] dashboard opens without layout issues
- [ ] symptom checker example is ready
- [ ] one sample skin image is ready
- [ ] disease trend dashboard filters are tested
- [ ] Gemini summary works
- [ ] one backup explanation is ready if internet is slow
- [ ] you practiced the 2-minute pitch at least 3 times

## Backup Answer If AI Is Slow
Say this:

> Our app supports local flows and visual modules even without a fast AI response. Gemini adds the intelligent explanation layer, but the product structure and value are still visible in the demo.

## Files You Can Open for Revision
- `docs/hackathon_playbook.html`
- `docs/hackathon_quick_notes.md`

## Final Advice
In the hackathon, do not try to explain every feature deeply. Focus on:
- the problem
- the 4 required modules
- Gemini integration
- responsive UI
- practical health impact

That will make your presentation much stronger than only listing screens.
