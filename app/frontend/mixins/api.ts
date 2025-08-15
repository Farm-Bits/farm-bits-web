import axios from 'axios';
import useToastStore from '@/stores/toast';

export function useApi<T>(method: string = 'GET', url: string, data: any = null): Promise<T> {
  const { addToast } = useToastStore();
  return new Promise((resolve, reject) => {
    axios({
      method,
      url: `${url}`,
      headers: { 'Content-Type': 'application/json' },
      data
    })
      .then((response) => {
        resolve(response.data);
      })
      .catch((error) => {
        addToast(
          'error',
          error.response?.statusText || 'Failed Server Request',
          error.response?.data?.error || 'Failed to retrieve data from server'
        );
        reject(error);
      });
  });
}
