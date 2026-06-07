// admin-web/src/App.tsx
import { useState } from 'react';
import Dashboard from './pages/Dashboard';
import IncidentMap from './pages/IncidentMap';

export default function App() {
  // Dùng state đơn giản để chuyển đổi giữa các trang mà không cần cài thư viện phức tạp
  const [currentPage, setCurrentPage] = useState<'dashboard' | 'map'>('dashboard');

  return (
    <div style={{ display: 'flex', minHeight: '100vh', fontFamily: 'Arial, sans-serif' }}>

      {/* THANH SIDEBAR BÊN TRÁI */}
      <div style={{ width: '250px', backgroundColor: '#001529', color: '#fff', padding: '20px' }}>
        <h3 style={{ textAlign: 'center', color: '#40a9ff' }}>UIRMS ADMIN</h3>
        <hr style={{ borderColor: '#333' }} />
        <ul style={{ listStyle: 'none', padding: 0, marginTop: '20px' }}>
          <li
            onClick={() => setCurrentPage('dashboard')}
            style={{ padding: '12px', cursor: 'pointer', backgroundColor: currentPage === 'dashboard' ? '#1890ff' : 'transparent', borderRadius: '4px', marginBottom: '10px' }}
          >
            📊 Bảng điều khiển
          </li>
          <li
            onClick={() => setCurrentPage('map')}
            style={{ padding: '12px', cursor: 'pointer', backgroundColor: currentPage === 'map' ? '#1890ff' : 'transparent', borderRadius: '4px' }}
          >
            🗺️ Bản đồ sự cố
          </li>
        </ul>
      </div>

      {/* VÙNG HIỂN THỊ NỘI DUNG BÊN PHẢI */}
      <div style={{ flex: 1, padding: '20px', backgroundColor: '#f5f5f5' }}>
        <header style={{ background: '#fff', padding: '15px', marginBottom: '20px', borderRadius: '8px', boxShadow: '0 2px 4px rgba(0,0,0,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>Chào, <strong>Dương Quốc Anh</strong> (Quản trị viên hệ thống)</span>
          <span style={{ color: 'green' }}>● Hệ thống trực tuyến</span>
        </header>

        {/* ĐIỀU HƯỚNG HIỂN THỊ TRANG */}
        {currentPage === 'dashboard' ? <Dashboard /> : <IncidentMap />}
      </div>

    </div>
  );
}