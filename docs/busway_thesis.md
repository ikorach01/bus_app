# BusWay: Design and Implementation of a Mobile Application for Navigation in an Urban Bus Transport Network Between Municipalities

## General Introduction

With the rapid rise of mobile technologies, smartphone applications now occupy a central place in users' daily lives. These digital tools, accessible anytime and anywhere, offer a multitude of services ranging from entertainment to practical task management, including communication, health, education, and mobility. This evolution has profoundly transformed how individuals interact with their environment, facilitating access to information and paving the way for new uses. In this context, the concept of the "smart city" has emerged, where technology serves to optimize urban services and improve citizens' quality of life. Among the major challenges of this transformation, smart mobility and navigation in urban transport networks play a key role, particularly in cities experiencing rapid demographic growth.

## Context

The rapid growth of urban populations in most major cities worldwide has led to a significant increase in daily commutes. This dynamic poses new challenges for municipalities, which must cope with rising traffic congestion, increased air pollution, wasted time for users, and difficulties in accessing public transport information.

Bus networks, in particular, are a cornerstone of urban public transport, efficiently connecting different neighborhoods and town halls. However, managing these networks becomes increasingly complex as demand grows and citizens' expectations evolve. Today, users want to plan their trips optimally, avoid delays, anticipate connections, and access reliable, up-to-date information. Traditional solutions (printed schedules, static maps) quickly show their limitations. The rise of smartphones and mobile apps presents new opportunities to rethink the user experience and modernize access to urban transport services.

## Problem Statement

Despite the availability and density of bus networks in most cities, users still face many obstacles in their daily use:
- Identifying optimal routes: It is not always easy to know which bus to take from one town hall to another, especially when multiple lines or transfers are required.
- Accessing real-time information: Theoretical schedules do not always reflect on-the-ground realities.
- Tracking bus locations: The lack of real-time tracking makes it difficult to anticipate bus arrivals, leading to frustration while waiting at stops.
- Trust in information: Available data (schedules, connections, wait times) is sometimes incomplete, outdated, or inaccessible.

## Objectives

The main objective of this work is the design and implementation of an innovative mobile application, called BusWay, dedicated to real-time guidance and tracking of buses in an inter-municipal urban network. This application aims to:
- Provide an interactive bus network map, allowing users to visualize all lines, stops, and possible routes.
- Display real-time bus locations by integrating dynamic data from a centralized database (Supabase).
- Enable personalized trip planning based on departure points, destinations, and user preferences.
- Improve the user experience with an intuitive, multilingual interface accessible to all profiles while promoting sustainable mobility.

## Contribution

Our contribution aligns with an innovative and modernizing approach to urban services. The BusWay project stands out through:
- Integration of cutting-edge technologies: Flutter for cross-platform development (Android/iOS), Supabase for real-time data management, and specialized libraries for mapping and geolocation.
- A robust data model enabling precise bus tracking, station and route management, and future expansion (alerts, favorites, statistics, etc.).

## Thesis Structure

This thesis is structured into three complementary chapters:
— The first chapter presents the foundations of mobile applications, their objectives, development
tools, and an overview of mobile operating systems, with a focus on Android and iOS. It sets the
project's technological and methodological framework.
— The second chapter focuses on the UML analysis and modeling of the application: detailed
needs identification, presentation of key diagrams (use case, class, sequence), and description of the
system's overall architecture.
— The third chapter details practical implementation: technology and language choices, code
organization, Supabase integration, key functionalities (route search, real-time tracking, user
management, etc.), and application presentation through screenshots.
Finally, a General Conclusion revisits the project's contributions, challenges encountered, solutions
implemented, and proposes future improvement perspectives.

## Conclusion

This thesis has detailed the implementation of the BusWay project, highlighting the integration of modern technologies and user-centric design. The application offers a complete solution for urban bus transport management, featuring real-time tracking and efficient route planning. BusWay demonstrates the potential of mobile applications in enhancing urban services and sets a foundation for future innovations in urban mobility solutions.

The project has successfully addressed key challenges in urban bus transport management by implementing real-time tracking using HERE API and Supabase, enabling efficient route planning with municipality integration, ensuring robust user authentication and authorization, and providing seamless navigation between driver and passenger interfaces. These features work together to create a comprehensive solution that improves the overall user experience and operational efficiency of urban bus transport.

Future work possibilities include: integrating additional transport modes, implementing predictive analytics for bus schedules, expanding multilingual support, developing advanced user feedback systems, and integrating with smart city infrastructure.
