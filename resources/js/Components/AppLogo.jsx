export default function AppLogo({ className = '' }) {
  return (
    <div className={`text-center ${className}`}>
      <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-100 mb-3">
        <svg className="w-10 h-10 text-blue-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
      </div>
      <h1 className="text-3xl font-bold text-blue-600">EventApp</h1>
    </div>
  );
}