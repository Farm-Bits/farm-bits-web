import { readonly, ref } from 'vue';
import { type AxiosResponse } from 'axios';
import useToastStore from '@/stores/toast';

export type ApiError = {
  error: string;
};

interface ApiCallOptions {
  errorTitle?: string;
  errorMessage?: string;
  successTitle?: string;
  successMessage?: string;
  showSuccessToast?: boolean;
  showErrorToast?: boolean;
};

type ApiCallResult<T> =
  | { success: true; data: T; response: AxiosResponse<T>; error?: never }
  | { success: false; data?: never; response?: never; error: ApiError };

export function useApiCall() {
  const loading = ref(false);
  const error = ref<ApiError | null>(null);

  const { addToast } = useToastStore();

  async function execute<T>(
    apiCall: () => Promise<AxiosResponse<T>>,
    options: ApiCallOptions = {}
  ): Promise<ApiCallResult<T>> {
    const {
      errorTitle = 'Error',
      errorMessage = 'An error occurred',
      successTitle = 'Success',
      successMessage = 'Operation completed successfully',
      showSuccessToast = false,
      showErrorToast = false
    } = options;

    loading.value = true;
    error.value = null;

    try {
      const response = await apiCall();

      if (showSuccessToast)
        addToast('success', successTitle, successMessage);

      return { success: true, data: response.data, response };
    } catch (err: any) {
      const apiError: ApiError = err.response?.data || { error: errorMessage };

      error.value = apiError;

      if (showErrorToast)
        addToast('error', errorTitle, apiError.error);

      console.error(`${errorTitle}:`, err);
      return { success: false, error: apiError };
    } finally {
      loading.value = false;
    }
  }

  return {
    loading: readonly(loading),
    error: readonly(error),
    execute
  };
}
