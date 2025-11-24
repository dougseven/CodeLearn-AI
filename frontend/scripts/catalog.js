/**
 * Course Catalog Data
 * Static data for course categories displayed on landing page
 * 
 * @module catalog
 */

// Course categories data (T012) - Based on data-model.md
export const courses = [
  {
    id: 'python',
    name: 'Python Programming',
    description: 'Learn Python from basics to advanced AI development.',
    icon: '/assets/icons/python.svg',
    difficulty: 'beginner',
    lessonCount: 24,
    enabled: true,
    color: '#3776ab', // Python blue
  },
  {
    id: 'java',
    name: 'Java Development',
    description: 'Master Java for enterprise and Android applications.',
    icon: '/assets/icons/java.svg',
    difficulty: 'intermediate',
    lessonCount: 18,
    enabled: true,
    color: '#007396', // Java blue
  },
  {
    id: 'rust',
    name: 'Rust Systems',
    description: 'Build safe, high-performance systems with Rust.',
    icon: '/assets/icons/rust.svg',
    difficulty: 'advanced',
    lessonCount: 12,
    enabled: true,
    color: '#ce422b', // Rust orange
  },
];

/**
 * Get difficulty badge color
 * @param {string} difficulty - beginner, intermediate, or advanced
 * @returns {string} CSS color value
 */
export function getDifficultyColor(difficulty) {
  const colors = {
    beginner: '#10b981', // Green
    intermediate: '#f59e0b', // Amber
    advanced: '#ef4444', // Red
  };
  return colors[difficulty] || '#6b7280';
}

/**
 * Get difficulty display label
 * @param {string} difficulty - beginner, intermediate, or advanced
 * @returns {string} Capitalized difficulty label
 */
export function getDifficultyLabel(difficulty) {
  return difficulty.charAt(0).toUpperCase() + difficulty.slice(1);
}

/**
 * Validate course data structure
 * @param {Object} course - Course object to validate
 * @returns {boolean} True if valid
 */
export function validateCourse(course) {
  const required = ['id', 'name', 'description', 'icon', 'difficulty', 'lessonCount', 'enabled'];
  return required.every((field) => field in course)
    && /^[a-z]+$/.test(course.id)
    && course.name.length >= 1 && course.name.length <= 30
    && course.description.length >= 50 && course.description.length <= 150
    && ['beginner', 'intermediate', 'advanced'].includes(course.difficulty)
    && course.lessonCount >= 0;
}

// Validate all courses on module load
courses.forEach((course) => {
  if (!validateCourse(course)) {
    console.warn(`Invalid course data for: ${course.id}`);
  }
});

export default courses;
