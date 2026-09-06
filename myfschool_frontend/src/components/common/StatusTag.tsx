import React from 'react';
import { Tag } from 'antd';
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  ClockCircleOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';
import type { AttendanceStatus } from '../../types/attendance';

interface StatusTagProps {
  status: AttendanceStatus | string;
}

export const StatusTag: React.FC<StatusTagProps> = ({ status }) => {
  switch (status) {
    case 'PRESENT':
      return (
        <Tag color="success" icon={<CheckCircleOutlined />}>
          Có mặt
        </Tag>
      );
    case 'EXCUSED_ABSENCE':
      return (
        <Tag color="processing" icon={<InfoCircleOutlined />}>
          Có phép
        </Tag>
      );
    case 'UNEXCUSED_ABSENCE':
      return (
        <Tag color="error" icon={<CloseCircleOutlined />}>
          Không phép
        </Tag>
      );
    case 'LATE':
      return (
        <Tag color="warning" icon={<ClockCircleOutlined />}>
          Đi muộn
        </Tag>
      );
    default:
      return <Tag>{status}</Tag>;
  }
};
