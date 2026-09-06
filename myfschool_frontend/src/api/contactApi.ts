import { axiosClient } from './axiosClient';
import type { TeacherContactDTO, SchoolDepartmentContact } from '../types/contact';

export const contactApi = {
  getTeachers: async (): Promise<TeacherContactDTO[]> => {
    const response = await axiosClient.get<TeacherContactDTO[]>('/contacts/me');
    return response.data;
  },

  getSchoolDepartments: async (): Promise<SchoolDepartmentContact[]> => {
    // School department information synchronized with mobile Flutter ContactService
    return [
      {
        id: 'dept_1',
        name: 'Văn phòng Ban Giám Hiệu',
        email: 'bgh@fpt.edu.vn',
        phoneNumber: '024 7300 1860',
        department: 'Ban Giám Hiệu',
        location: 'Phòng 201 - Tòa nhà Điều hành',
        workingHours: '07:30 - 17:00 (Thứ 2 - Thứ 6)',
        description: 'Tiếp nhận ý kiến đóng góp, giải quyết các thủ tục học vụ và kiến nghị chính thức từ phụ huynh.',
      },
      {
        id: 'dept_2',
        name: 'Phòng Đào tạo & Tuyển sinh',
        email: 'fptschool@fpt.edu.vn',
        phoneNumber: '024 7300 1866',
        department: 'Khối Đào tạo',
        location: 'Phòng 102 - Tòa nhà Alpha',
        workingHours: '08:00 - 17:30 (Thứ 2 - Thứ 7)',
        description: 'Hỗ trợ đăng ký nhập học, chuyển lớp, bảng điểm, thời khóa biểu và chương trình giảng dạy.',
      },
      {
        id: 'dept_3',
        name: 'Phòng Công tác Học sinh & Tâm lý Học đường',
        email: 'cths@fpt.edu.vn',
        phoneNumber: '024 7300 1868',
        department: 'Hỗ trợ Học sinh',
        location: 'Phòng 105 - Tòa nhà Beta',
        workingHours: '08:00 - 16:30 (Thứ 2 - Thứ 6)',
        description: 'Tư vấn tâm lý, câu lạc bộ ngoại khóa, rèn luyện nề nếp kỷ luật và hoạt động phong trào.',
      },
      {
        id: 'dept_4',
        name: 'Phòng Y tế & Chăm sóc Sức khỏe Học đường',
        email: 'yte@fpt.edu.vn',
        phoneNumber: '024 7300 1869',
        department: 'Y tế & Bếp ăn',
        location: 'Tầng 1 - Khu ký túc xá / Nhà ăn',
        workingHours: '24/7 trong tuần học',
        description: 'Chăm sóc sức khỏe ban đầu, sơ cứu tai nạn học đường, bảo hiểm y tế và an toàn vệ sinh thực phẩm.',
      },
      {
        id: 'dept_5',
        name: 'Đường dây nóng Khẩn cấp (Hotline 24/7)',
        email: 'hotline@fpt.edu.vn',
        phoneNumber: '1900 6868',
        department: 'An ninh & Trật tự',
        location: 'Cổng chính & Phòng Bảo vệ',
        workingHours: '24/7 liên tục',
        description: 'Tiếp nhận thông tin sự cố khẩn cấp, an ninh an toàn trường học và xe bus đưa đón.',
      },
    ];
  },
};
